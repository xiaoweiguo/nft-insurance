// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "./library/LinkedList.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/IInsurance.sol";

contract Insurance is AutomationCompatibleInterface, IInsurance {
  using LinkedListLib for LinkedListLib.UintLinkedList;

  address immutable Azuki_Address;
  address payable immutable Pool_Address;
  IDAO immutable DAO;
  uint policyIdCounter;
  LinkedListLib.UintLinkedList linkedListPolicies;

  /// @notice policyId => InsurancePolicy
  mapping(uint => InsurancePolicy) public insurancePolicies;
  /// @notice tokenId => policyId
  mapping(uint => uint) public tokenIdToPolicyId;

  constructor(address AzukiAddress, address DAOAddress, address PoolAddress) {
    Azuki_Address = AzukiAddress;
    DAO = IDAO(DAOAddress);
    Pool_Address = payable(PoolAddress);
  }

  struct InsurancePolicy {
    uint policyId;
    uint tokenId;
    address beneficiaryAddress;
    uint startTime;
    uint insuranceDuration;
    /// @notice the premium paid by the policy holder
    uint insurancePremium;
    /// @notice the amount triggered to settle the claim
    uint claimTrigger;
    /// @notice record whether the insurance is activated
    bool isActive;
  }

  /**
   * @notice calculate the required premium
   * @param tokenId the token id of the NFT
   * @param insuranceDuration the duration of the insurance
   */
  function calculatePremium(uint tokenId, uint insuranceDuration) public view returns (uint price) {
    return 2e18;
  }

  modifier onlyDAO() {
    require(msg.sender == address(DAO), "Only DAO can call this function");
    _;
  }

  function createProposal(uint tokenId_, uint insuranceDuration, uint claimTrigger) public payable {
    uint insurancePremium = calculatePremium(tokenId_, insuranceDuration);
    require(msg.value >= insurancePremium, "Insufficient premium paid");
    DAO.createProposal(tokenId_, insuranceDuration, insurancePremium, claimTrigger, msg.sender);
    if (msg.value > insurancePremium) {
      payable(msg.sender).transfer(msg.value - insurancePremium);
    }
  }

  function proposalFailed(address _to, uint price) external onlyDAO {
    payable(_to).transfer(price);
  }

  /**
   * @notice create a new insurance policy
   */
  function createPolicy(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) public onlyDAO returns (uint policyId) {
    require(tokenIdToPolicyId[tokenId_] == 0, "Policy already exists");
    policyId = ++policyIdCounter;
    Pool_Address.transfer(insurancePremium);
    insurancePolicies[policyId] = InsurancePolicy(
      policyId,
      tokenId_,
      beneficiaryAddress,
      block.timestamp,
      insuranceDuration,
      insurancePremium,
      claimTrigger,
      true
    );
    tokenIdToPolicyId[tokenId_] = policyId;

    linkedListPolicies.add(policyId);
    emit PolicyCreated(policyId, tokenId_, block.timestamp);
  }

  /**
   * @notice cancel an existing insurance policy
   */
  function _cancelPolicy(uint policyId) internal {
    linkedListPolicies.remove(policyId);
    insurancePolicies[policyId].isActive = false;
    uint tokenId = insurancePolicies[policyId].tokenId;
    delete tokenIdToPolicyId[tokenId];
  }

  /**
   * @notice insurance expiration not triggered
   */
  function expiredDown(uint policyId) public returns (bool) {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(_checkExpiredDown(policyId), "Policy is not expired");

    _cancelPolicy(policyId);

    return true;
  }

  function _triggerInsurance(uint policyId) internal returns (bool) {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(_checkExpiredDown(policyId), "Policy is expired");

    DAO.triggerInsurance(insurancePolicies[policyId].beneficiaryAddress, insurancePolicies[policyId].claimTrigger);
    _cancelPolicy(policyId);

    return true;
  }

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
    upkeepNeeded = false;
    uint[] memory results = new uint[](policyIdCounter);
    uint policyId = linkedListPolicies.getNode(0).next;
    uint counter = 0;
    while (policyId != 0) {
      if (_checkExpiredDown(policyId)) {
        results[counter] = policyId;
        if (!upkeepNeeded) {
          upkeepNeeded = true;
        }
      }
      policyId = linkedListPolicies.getNode(policyId).next;
    }
    performData = abi.encode(results);
    return (upkeepNeeded, performData);
  }

  function _checkExpiredDown(uint policyId) internal view returns (bool) {
    return insurancePolicies[policyId].startTime + insurancePolicies[policyId].insuranceDuration <= block.timestamp;
  }

  function performUpkeep(bytes calldata performData) external override {
    uint[] memory results = abi.decode(performData, (uint[]));
    for (uint i = 0; i < results.length; i++) {
      if (results[i] == 0) {
        break;
      } else if (_checkExpiredDown(results[i])) {
        expiredDown(results[i]);
      }
    }
  }
}
