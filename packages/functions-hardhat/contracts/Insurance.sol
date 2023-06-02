// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./insurance/library/LinkedList.sol";

import "./insurance/interfaces/IDAO.sol";
import "./insurance/interfaces/IInsurance.sol";

contract Insurance is AutomationCompatibleInterface, IInsurance {
  using LinkedListLib for LinkedListLib.UintLinkedList;

  address immutable functionsConsumerAddress;
  address immutable Azuki_Address;
  address payable immutable Pool_Address;

  IDAO immutable DAO;
  AggregatorV3Interface internal nftFloorPriceFeed;

  uint premiumRateFactor = 30; // 30%
  uint policyIdCounter;

  LinkedListLib.UintLinkedList linkedListPolicies;

  /// @notice userAddress => policyId
  mapping(address => uint[]) userToPolicyId;
  /// @notice policyId => InsurancePolicy
  mapping(uint => InsurancePolicy) insurancePolicies;
  /// @notice tokenId => policyId
  mapping(uint => uint) tokenIdToPolicyId;

  constructor(address AzukiAddress, address DAOAddress, address PoolAddress, address FunctionsConsumerAddress) {
    Azuki_Address = AzukiAddress;
    DAO = IDAO(DAOAddress);
    Pool_Address = payable(PoolAddress);
    functionsConsumerAddress = FunctionsConsumerAddress;
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

  function createProposal(uint tokenId_, uint insuranceDuration, uint claimTrigger) public payable {
    require(insuranceDuration % 1 days == 0 && insuranceDuration / 1 days < 6, "Invalid insurance duration");
    require(
      claimTrigger == 15e18 ||
        claimTrigger == 13e18 ||
        claimTrigger == 12e18 ||
        claimTrigger == 11e18 ||
        claimTrigger == 105e17,
      "Invalid claim trigger"
    );
    uint insurancePremium = calculatePremium(insuranceDuration, claimTrigger);
    require(msg.value >= insurancePremium, "Insufficient premium paid");
    DAO.createProposal(tokenId_, insuranceDuration, insurancePremium, claimTrigger, msg.sender);
    if (msg.value > insurancePremium) {
      payable(msg.sender).transfer(msg.value - insurancePremium);
    }
  }

  function proposalFailed(address _to, uint price) external onlyDAO {
    payable(_to).transfer(price);
    emit ProposalFailed(_to, price);
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
   * @notice insurance expiration not triggered
   */
  function expiredDown(uint policyId) public {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(_checkExpiredDown(policyId), "Policy is not expired");

    _cancelPolicy(policyId);
    emit ExpiredDown(policyId);
  }

  /// chainlink automation
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
   * Returns the latest price
   */
  function _getLatestNFTPrice() internal view returns (uint) {
    (, int nftFloorPrice, , , ) = nftFloorPriceFeed.latestRoundData();
    return uint(nftFloorPrice);
  }

  /**
   * @notice cancel an existing insurance policy
   */
  function _cancelPolicy(uint policyId) internal {
    linkedListPolicies.remove(policyId);
    insurancePolicies[policyId].isActive = false;
    uint tokenId = insurancePolicies[policyId].tokenId;
    address beneficiaryAddress = insurancePolicies[policyId].beneficiaryAddress;
    uint[] storage policies = userToPolicyId[beneficiaryAddress];
    for (uint i = 0; i < policies.length; i++) {
      if (policies[i] == policyId) {
        policies[i] = policies[policies.length - 1];
        policies.pop();
        break;
      }
    }
    delete tokenIdToPolicyId[tokenId];
  }

  function triggerInsurance(uint policyId) internal {
    require(insurancePolicies[policyId].isActive == true, "Policy is not active");
    require(!_checkExpiredDown(policyId), "Policy is expired");
    require(msg.sender == functionsConsumerAddress, "only functionsConsumer can call this function");

    DAO.triggerInsurance(insurancePolicies[policyId].beneficiaryAddress, insurancePolicies[policyId].claimTrigger);
    _cancelPolicy(policyId);
  }

  function _checkExpiredDown(uint policyId) internal view returns (bool) {
    return insurancePolicies[policyId].startTime + insurancePolicies[policyId].insuranceDuration <= block.timestamp;
  }

  /// view function

  /**
   * @notice calculate the required premium
   * @param insuranceDuration the duration of the insurance
   * @param claimTrigger the claim trigger
   */
  function calculatePremium(uint insuranceDuration, uint claimTrigger) public view returns (uint price) {
    uint NFTLatestPrice = _getLatestNFTPrice();
    price = (NFTLatestPrice * premiumRateFactor * claimTrigger * insuranceDuration) / 1 days / 100;
  }

  function checkInsuranceTriggered(uint tokenId, uint latestedPrice) public view returns (bool) {
    uint policyId = tokenIdToPolicyId[tokenId];
    return insurancePolicies[policyId].isActive && latestedPrice <= insurancePolicies[policyId].claimTrigger;
  }

  function getPolicyInfoByPolicyId(uint policyId) external view returns (InsurancePolicy memory) {
    return insurancePolicies[policyId];
  }

  function getPolicyInfoByTokenId(uint tokenId) external view returns (InsurancePolicy memory) {
    return insurancePolicies[tokenIdToPolicyId[tokenId]];
  }

  function getPolicyIdByTokenId(uint tokenId) external view returns (uint) {
    return tokenIdToPolicyId[tokenId];
  }

  function getPolicyInfoByUser(address userAddress) external view returns (InsurancePolicy[] memory) {
    uint[] memory policies = userToPolicyId[userAddress];
    InsurancePolicy[] memory results = new InsurancePolicy[](policies.length);
    for (uint i = 0; i < policies.length; i++) {
      results[i] = insurancePolicies[policies[i]];
    }
    return results;
  }
}
