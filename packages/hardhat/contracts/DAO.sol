// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IInsurance.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IDAO.sol";

import "./library/LinkedList.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract DAO is Ownable, ERC20, IDAO, AutomationCompatibleInterface {
  using SafeMath for uint;
  using LinkedListLib for LinkedListLib.UintLinkedList;

  LinkedListLib.UintLinkedList linkedListProposals;
  IInsurance public insurance;
  ILiquidityPool public immutable pool;
  uint public numStakeholders;
  uint public proposalIdCounter;
  uint public constant SHORTEST_STAKE_TIME = 10 days;
  uint public constant MAX_PROPOSAL_DURATION = 1 days;

  /// @notice tokenId => Proposal
  mapping(uint => Proposal) tokenIdToProposal;
  mapping(address => bool) isStakeholder;
  mapping(address => StakingHolder) stakingHolders;
  /// @notice proposalId => Proposal
  mapping(uint => Proposal) proposals;
  /// @notice user => proposalId => isVoted
  mapping(address => mapping(uint => bool)) isVoted;

  constructor(address poolAddress) ERC20("Azuki DAO", "AZDAO") {
    pool = ILiquidityPool(poolAddress);
  }

  struct StakingHolder {
    uint startTime;
    uint stakingAmount;
  }

  struct Proposal {
    uint proposalId;
    uint tokenId;
    uint insuranceDuration;
    uint insurancePremium;
    uint createTime;
    uint claimTrigger;
    uint numVotes;
    uint targetVotes;
    address beneficiaryAddress;
    bool isActive;
    bool isPass;
  }

  function _isExpired(uint proposalId) internal view returns (bool) {
    return block.timestamp >= proposals[proposalId].createTime.add(MAX_PROPOSAL_DURATION);
  }

  function _removeProposal(uint proposalId) internal {
    linkedListProposals.remove(proposalId);
    proposals[proposalId].isActive = false;
    delete tokenIdToProposal[proposals[proposalId].tokenId];
  }

  function proposalExpired(uint proposalId) external {
    insurance.proposalFailed(proposals[proposalId].beneficiaryAddress, proposals[proposalId].insurancePremium);
  }

  function stake(uint stakingAmount) external payable {
    require(msg.value == stakingAmount, "Incorrect staking amount");
    if (isStakeholder[msg.sender] == false) {
      numStakeholders = numStakeholders.add(1);
      isStakeholder[msg.sender] = true;
    }
    uint mintAmount;
    if (address(pool).balance == 0) {
      mintAmount = stakingAmount;
    } else {
      mintAmount = msg.value.mul(totalSupply()).div(address(pool).balance);
    }

    stakingHolders[msg.sender].stakingAmount = stakingHolders[msg.sender].stakingAmount.add(mintAmount);
    stakingHolders[msg.sender].startTime = block.timestamp;
    _mint(msg.sender, mintAmount);
    payable(address(pool)).transfer(stakingAmount);
  }

  function getAmount(uint stakingAmount) public view returns (uint) {
    uint perAZDAOToETH = address(pool).balance.div(totalSupply());
    return stakingAmount.mul(perAZDAOToETH);
  }

  function withdraw(uint stakingAmount) external {
    require(stakingHolders[msg.sender].stakingAmount >= stakingAmount, "Insufficient staking amount");
    require(block.timestamp >= stakingHolders[msg.sender].startTime.add(10 days), "Staking period not over");
    uint withdrawAmount = getAmount(stakingAmount);
    if (stakingHolders[msg.sender].stakingAmount == 0) {
      isStakeholder[msg.sender] = false;
      numStakeholders = numStakeholders.sub(1);
    }
    stakingHolders[msg.sender].stakingAmount = stakingHolders[msg.sender].stakingAmount.sub(stakingAmount);
    _burn(msg.sender, stakingAmount);
    pool.sendEth(payable(msg.sender), withdrawAmount);
  }

  function createProposal(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) external {
    require(msg.sender == address(insurance), "Only insurance can call");
    require(proposals[tokenId_].isActive == false, "Proposal already exists");
    proposalIdCounter = proposalIdCounter.add(1);
    uint proposalId = proposalIdCounter;
    linkedListProposals.add(proposalId);

    proposals[proposalId] = Proposal(
      proposalId,
      tokenId_,
      insuranceDuration,
      insurancePremium,
      block.timestamp,
      claimTrigger,
      0,
      numStakeholders > 2 ? numStakeholders.div(2) : numStakeholders,
      beneficiaryAddress,
      true,
      false
    );
    tokenIdToProposal[tokenId_] = proposals[proposalId];
  }

  function vote(uint proposalId) external {
    require(proposals[proposalId].isActive == true, "Proposal is not active");
    require(proposals[proposalId].isPass == false, "Proposal already pass");
    require(isVoted[msg.sender][proposalId] == false, "Already voted");
    Proposal storage proposal = proposals[proposalId];
    isVoted[msg.sender][proposalId] = true;
    proposal.numVotes = proposal.numVotes.add(1);
    if (_checkProposal(proposalId)) {
      proposal.isPass = true;
      _removeProposal(proposalId);
      _createPolicy(
        proposal.tokenId,
        proposal.insuranceDuration,
        proposal.insurancePremium,
        proposal.claimTrigger,
        proposal.beneficiaryAddress
      );
    }
  }

  function _createPolicy(
    uint tokenId,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) internal {
    insurance.createPolicy(tokenId, insuranceDuration, insurancePremium, claimTrigger, beneficiaryAddress);
  }

  function _checkProposal(uint proposalId) internal view returns (bool) {
    return proposals[proposalId].numVotes >= proposals[proposalId].targetVotes;
  }

  function setInsuranceAddress(address _insuranceAddress) external onlyOwner {
    insurance = IInsurance(_insuranceAddress);
  }

  function triggerInsurance(address _to, uint amount) external {
    require(msg.sender == address(insurance), "Only insurance can call");
    pool.sendEth(payable(_to), amount);
  }

  /// view function

  function getStakingStartTime(address user) external view returns (uint) {
    return stakingHolders[user].startTime;
  }

  function getStakingAmount(address user) external view returns (uint) {
    return stakingHolders[user].stakingAmount;
  }

  function checkIsStakeholder(address user) external view returns (bool) {
    return isStakeholder[user];
  }

  function checkIsVoted(address user, uint proposalId) external view returns (bool) {
    return isVoted[user][proposalId];
  }

  function getProposal(uint proposalId) external view returns (Proposal memory proposal) {
    proposal = proposals[proposalId];
  }

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
    upkeepNeeded = false;
    uint proposalId = linkedListProposals.getNode(0).next;
    uint[] memory result = new uint[](proposalIdCounter);
    uint count = 0;
    while (proposalId != 0) {
      if (_isExpired(proposalId)) {
        if (!upkeepNeeded) {
          upkeepNeeded = true;
        }
        result[count++] = proposalId;
        proposalId = linkedListProposals.getNode(proposalId).next;
      } else {
        break;
      }
    }
    performData = abi.encode(result);
  }

  function performUpkeep(bytes calldata performData) external override {
    uint[] memory result = abi.decode(performData, (uint[]));
    for (uint i = 0; i < result.length; i++) {
      if (result[i] == 0) {
        break;
      }
      insurance.proposalFailed(proposals[result[i]].beneficiaryAddress, proposals[result[i]].insurancePremium);
      _removeProposal(result[i]);
    }
  }
}
