// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IInsurance.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IDAO.sol";

import "./library/LinkedList.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract DAO is Ownable, ERC20, IDAO, AutomationCompatibleInterface {
  using LinkedListLib for LinkedListLib.UintLinkedList;

  LinkedListLib.UintLinkedList linkedListProposals;
  IInsurance public insurance;
  ILiquidityPool public immutable pool;
  uint public numStakeholders;
  uint public proposalIdCounter;

  /// Constants
  uint public constant SHORTEST_STAKE_TIME = 5 seconds;
  uint public constant MAX_PROPOSAL_DURATION = 1 days;

  /// Mapping: tokenId => Proposal
  mapping(uint => Proposal) tokenIdToProposal;
  mapping(address => bool) isStakeholder;
  mapping(address => StakingHolder) stakingHolders;
  /// Mapping: proposalId => Proposal
  mapping(uint => Proposal) proposals;
  /// Mapping: user => proposalId => isVoted
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

  /**
   * @notice Triggered when a proposal expires and is considered failed.
   * @param proposalId The ID of the expired proposal.
   */
  function proposalExpired(uint proposalId) external {
    insurance.proposalFailed(proposals[proposalId].beneficiaryAddress, proposals[proposalId].insurancePremium);
  }

  /**
   * @notice Stake AZDAO tokens in the DAO.
   * @param stakingAmount The amount of AZDAO tokens to stake.
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
   * @notice Calculate the ETH amount equivalent to the staked AZDAO tokens.
   * @param stakingAmount The amount of AZDAO tokens staked.
   * @return The corresponding ETH amount.
   */
  function getAmount(uint stakingAmount) external view returns (uint) {
    return _getAmount(stakingAmount);
  }

  /**
   * @notice Withdraw staked AZDAO tokens from the DAO.
   * @param stakingAmount The amount of AZ
