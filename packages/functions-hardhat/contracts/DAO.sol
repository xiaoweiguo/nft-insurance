// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./insurance/interfaces/IInsurance.sol";
import "./insurance/interfaces/ILiquidityPool.sol";
import "./insurance/interfaces/IDAO.sol";

import "./insurance/library/LinkedList.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract DAO is Ownable, ERC20, IDAO, AutomationCompatibleInterface {
  using LinkedListLib for LinkedListLib.UintLinkedList;

  LinkedListLib.UintLinkedList linkedListProposals; // List of proposal IDs
  IInsurance public insurance; // Insurance contract
  ILiquidityPool public immutable pool; // Liquidity pool contract
  uint public numStakeholders; // Number of stakeholders
  uint public proposalIdCounter; // Counter for proposal IDs

  /// Constants
  uint public constant SHORTEST_STAKE_TIME = 5 seconds;
  uint public constant MAX_PROPOSAL_DURATION = 1 days;

  /// Mapping of tokenId to Proposal struct
  mapping(uint => Proposal) tokenIdToProposal;
  mapping(address => bool) isStakeholder; // Mapping to check if an address is a stakeholder
  mapping(address => StakingHolder) stakingHolders; // Mapping of address to StakingHolder struct
  mapping(uint => Proposal) proposals; // Mapping of proposalId to Proposal struct
  mapping(address => mapping(uint => bool)) isVoted; // Mapping of user to proposalId to check if the user has voted

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

  /**
   * @dev Called when a proposal expires to indicate a failed proposal.
   * @param proposalId The ID of the expired proposal.
   */
  function proposalExpired(uint proposalId) external {
    insurance.proposalFailed(proposals[proposalId].beneficiaryAddress, proposals[proposalId].insurancePremium);
  }

  /**
   * @dev Allows a user to stake tokens in the DAO.
   * @param stakingAmount The amount of tokens to stake.
   */
  function stake(uint stakingAmount) external payable {
    require(msg.value == stakingAmount, "Incorrect staking amount");
    if (isStakeholder[msg.sender] == false) {
      ++numStakeholders;
      isStakeholder[msg.sender] = true;
    }
    uint mintAmount;
    if (address(pool).balance == 0) {
      mintAmount = stakingAmount;
    } else {
      mintAmount = (msg.value * totalSupply()) / (address(pool).balance);
    }

    stakingHolders[msg.sender].stakingAmount = stakingHolders[msg.sender].stakingAmount + mintAmount;
    stakingHolders[msg.sender].startTime = block.timestamp;
    _mint(msg.sender, mintAmount);
    payable(address(pool)).transfer(stakingAmount);

    emit Stake(msg.sender, stakingAmount, block.timestamp);
  }

  /**
   * @dev Calculates the amount of ETH equivalent to the staking amount.
   * @param stakingAmount The staking amount in tokens.
   * @return The equivalent amount in ETH.
   */
  function getAmount(uint stakingAmount) external view returns (uint) {
    return _getAmount(stakingAmount);
  }

  /**
   * @dev Allows a user to withdraw their staked tokens.
   * @param stakingAmount The amount of tokens to withdraw.
   */
  function withdraw(uint stakingAmount) external {
    require(stakingHolders[msg.sender].stakingAmount >= stakingAmount, "Insufficient staking amount");
    require(block.timestamp >= stakingHolders[msg.sender].startTime + SHORTEST_STAKE_TIME, "Staking period not over");
    uint withdrawAmount = _getAmount(stakingAmount);
    if (stakingHolders[msg.sender].stakingAmount == 0) {
      isStakeholder[msg.sender] = false;
      --numStakeholders;
    }
    stakingHolders[msg.sender].stakingAmount -= stakingAmount;
    _burn(msg.sender, stakingAmount);
    pool.sendEth(payable(msg.sender), withdrawAmount);

    emit Withdraw(msg.sender, stakingAmount, block.timestamp);
  }

  /**
   * @dev Creates a new proposal.
   * @param tokenId_ The ID of the token.
   * @param insuranceDuration The duration of the insurance.
   * @param insurancePremium The premium amount for the insurance.
   * @param claimTrigger The trigger amount for the insurance claim.
   * @param beneficiaryAddress The address of the beneficiary.
   */
  function createProposal(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) external {
    require(msg.sender == address(insurance), "Only insurance can call");
    require(proposals[tokenId_].isActive == false, "Proposal already exists");
    uint proposalId = ++proposalIdCounter;
    linkedListProposals.add(proposalId);

    proposals[proposalId] = Proposal(
      proposalId,
      tokenId_,
      insuranceDuration,
      insurancePremium,
      block.timestamp,
      claimTrigger,
      0,
      numStakeholders > 2 ? numStakeholders / 2 : numStakeholders,
      beneficiaryAddress,
      true,
      false
    );
    tokenIdToProposal[tokenId_] = proposals[proposalId];

    emit CreateProposal(proposalId, tokenId_, beneficiaryAddress, block.timestamp);
  }

  /**
   * @dev Allows a stakeholder to vote on a proposal.
   * @param proposalId The ID of the proposal.
   */
  function vote(uint proposalId) external {
    require(isStakeholder[msg.sender] == true, "Only DAO member can call");
    require(proposals[proposalId].isActive == true, "Proposal is not active");
    require(proposals[proposalId].isPass == false, "Proposal already pass");
    require(isVoted[msg.sender][proposalId] == false, "Already voted");
    Proposal storage proposal = proposals[proposalId];
    isVoted[msg.sender][proposalId] = true;
    ++proposal.numVotes;
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

    emit Vote(msg.sender, proposalId, block.timestamp);
  }

  /**
   * @dev Sets the address of the insurance contract.
   * @param _insuranceAddress The address of the insurance contract.
   */
  function setInsuranceAddress(address _insuranceAddress) external onlyOwner {
    insurance = IInsurance(_insuranceAddress);
  }

  /**
   * @dev Triggers the insurance contract to send ETH to a specified address.
   * @param _to The address to send ETH to.
   * @param amount The amount of ETH to send.
   */
  function triggerInsurance(address _to, uint amount) external {
    require(msg.sender == address(insurance), "Only insurance can call");
    pool.sendEth(payable(_to), amount);
  }

  /**
   * @dev Checks whether upkeep is needed for the DAO contract.
   * @param data Not used.
   * @return upkeepNeeded Whether upkeep is needed.
   * @return performData Not used.
   */
  function checkUpkeep(bytes calldata data) external view override returns (bool upkeepNeeded, bytes memory performData) {
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

  /**
   * @dev Performs the upkeep for the DAO contract.
   * @param performData The data for performing the upkeep.
   */
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
