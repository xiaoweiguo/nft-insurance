// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./library/LinkedList.sol";

import "./interfaces/IDAO.sol";
import "./interfaces/IInsurance.sol";

/**
 * @title Insurance Contract
 * @dev A contract that allows users to create and manage insurance policies.
 */
contract Insurance is AutomationCompatibleInterface, IInsurance {
  using LinkedListLib for LinkedListLib.UintLinkedList;

  AggregatorV3Interface internal nftFloorPriceFeed;
  address immutable Azuki_Address;
  address payable immutable Pool_Address;
  IDAO immutable DAO;

  uint premiumRateFactor = 30; // 30%
  uint policyIdCounter;
  LinkedListLib.UintLinkedList linkedListPolicies;

  /// @notice userAddress => policyId
  mapping(address => uint[]) userToPolicyId;
  /// @notice policyId => InsurancePolicy
  mapping(uint => InsurancePolicy) insurancePolicies;
  /// @notice tokenId => policyId
  mapping(uint => uint) tokenIdToPolicyId;

  constructor(address AzukiAddress, address DAOAddress, address PoolAddress) {
    Azuki_Address = AzukiAddress;
    DAO = IDAO(DAOAddress);
    Pool_Address = payable(PoolAddress);
    nftFloorPriceFeed = AggregatorV3Interface(0x16c74d1f6986c6Ffb48540b178fF8Cb0ED9F13b0);
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

  modifier onlyDAO() {
    require(msg.sender == address(DAO), "Only DAO can call this function");
    _;
  }

  /**
   * @notice Create a proposal for insurance policy creation
   * @param tokenId_ The ID of the token to be insured
   * @param insuranceDuration The duration of the insurance policy in seconds
   * @param claimTrigger The claim trigger amount
   */
  function createProposal(uint tokenId_, uint insuranceDuration, uint claimTrigger) public payable {
    uint insurancePremium = calculatePremium(insuranceDuration, claimTrigger);
    require(msg.value >= insurancePremium, "Insufficient premium paid");
    DAO.createProposal(tokenId_, insuranceDuration, insurancePremium, claimTrigger, msg.sender);
    if (msg.value > insurancePremium) {
      payable(msg.sender).transfer(msg.value - insurancePremium);
    }
  }

  /**
   * @notice Handle the failed proposal
   * @param _to The address to refund the premium
   * @param price The premium amount to refund
   */
  function proposalFailed(address _to, uint price) external onlyDAO {
    payable(_to).transfer(price);
    emit ProposalFailed(_to, price);
  }

  /**
   * @notice Create a new insurance policy
   * @param tokenId_ The ID of the token to be insured
   * @param insuranceDuration The duration of the insurance policy in seconds
   * @param insurancePremium The premium amount paid by the policy holder
   * @param claimTrigger The claim trigger amount
   * @param beneficiaryAddress The address of the policy beneficiary
   * @return policyId The ID of the created insurance policy
   */
  function createPolicy(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) external onlyDAO returns (uint policyId) {
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
    uint[] storage policies = userToPolicyId[beneficiaryAddress];
    policies.push(policyId);
    tokenIdToPolicyId[tokenId_] = policyId;

    linkedListPolicies.add(policyId);
    emit PolicyCreated(policyId, tokenId_, block.timestamp);
  }

  /**
   * @notice Expire an insurance policy that is not triggered
   * @param policyId The ID of the insurance policy to expire
   */
  function expiredDown(uint policyId) public {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(_checkExpiredDown(policyId), "Policy is not expired");

    _cancelPolicy(policyId);
    emit ExpiredDown(policyId);
  }

  /// chainlink automation

  /**
   * @notice Check if upkeep is needed
   * @param data Additional data (not used)
   * @return upkeepNeeded True if upkeep is needed, false otherwise
   * @return performData The data to perform the upkeep
   */
  function checkUpkeep(bytes calldata data) external view override returns (bool upkeepNeeded, bytes memory performData) {
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

  /**
   * @notice Perform the upkeep
   * @param performData The data to perform the upkeep
   */
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

  ///internal function

  /**
   * @notice Get the latest NFT price from the price feed
   * @return The latest NFT price
   */
  function _getLatestNFTPrice() internal view returns (uint) {
    (, int nftFloorPrice, , , ) = nftFloorPriceFeed.latestRoundData();
    return uint(nftFloorPrice);
  }

  /**
   * @notice Cancel an existing insurance policy
   * @param policyId The ID of the insurance policy to cancel
   */
  function _cancelPolicy(uint policyId) internal {
    linkedListPolicies.remove(policyId);
    insurancePolicies[policyId].isActive = false;
    uint tokenId = insurancePolicies[policyId].tokenId;
    delete tokenIdToPolicyId[tokenId];
  }

  /**
   * @notice Trigger an insurance policy and settle the claim
   * @param policyId The ID of the insurance policy to trigger
   */
  function _triggerInsurance(uint policyId) internal {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(_checkExpiredDown(policyId), "Policy is expired");

    DAO.triggerInsurance(insurancePolicies[policyId].beneficiaryAddress, insurancePolicies[policyId].claimTrigger);
    _cancelPolicy(policyId);
  }

  /**
   * @notice Check if an insurance policy has expired
   * @param policyId The ID of the insurance policy to check
   * @return True if the policy has expired, false otherwise
   */
  function _checkExpiredDown(uint policyId) internal view returns (bool) {
    return insurancePolicies[policyId].startTime + insurancePolicies[policyId].insuranceDuration <= block.timestamp;
  }

  /// view function

  /**
   * @notice Calculate the required premium for an insurance policy
   * @param insuranceDuration The duration of the insurance policy in seconds
   * @param claimTrigger The claim trigger amount
   * @return price The calculated premium price
   */
  function calculatePremium(uint insuranceDuration, uint claimTrigger) public view returns (uint price) {
    require(insuranceDuration % 1 days == 0 && insuranceDuration / 1 days < 6, "Invalid insurance duration");
    require(
      claimTrigger == 15e18 ||
        claimTrigger == 13e18 ||
        claimTrigger == 12e18 ||
        claimTrigger == 11e18 ||
        claimTrigger == 105e17,
      "Invalid claim trigger"
    );
    uint NFTLatestPrice = _getLatestNFTPrice();
    price = (NFTLatestPrice * claimTrigger * premiumRateFactor * insuranceDuration) / 1 days / 100;
  }

  /**
   * @notice Get information about an insurance policy by policy ID
   * @param policyId The ID of the insurance policy
   * @return The InsurancePolicy struct
   */
  function getPolicyInfoByPolicyId(uint policyId) external view returns (InsurancePolicy memory) {
    return insurancePolicies[policyId];
  }

  /**
   * @notice Get information about an insurance policy by token ID
   * @param tokenId The ID of the token associated with the policy
   * @return The InsurancePolicy struct
   */
  function getPolicyInfoByTokenId(uint tokenId) external view returns (InsurancePolicy memory) {
    return insurancePolicies[tokenIdToPolicyId[tokenId]];
  }

  /**
   * @notice Get the policy ID associated with a token ID
   * @param tokenId The ID of the token
   * @return The policy ID
   */
  function getPolicyIdByTokenId(uint tokenId) external view returns (uint) {
    return tokenIdToPolicyId[tokenId];
  }

  /**
   * @notice Get information about insurance policies associated with a user
   * @param userAddress The address of the user
   * @return An array of InsurancePolicy structs
   */
  function getPolicyInfoByUser(address userAddress) external view returns (InsurancePolicy[] memory) {
    uint[] memory policies = userToPolicyId[userAddress];
    InsurancePolicy[] memory results = new InsurancePolicy[](policies.length);
    for (uint i = 0; i < policies.length; i++) {
      results[i] = insurancePolicies[policies[i]];
    }
    return results;
  }
}
