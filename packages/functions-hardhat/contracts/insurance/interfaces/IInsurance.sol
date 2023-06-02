// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IInsurance {
  event PolicyCreated(uint indexed policyId, uint tokenId, uint startTime);
  event ProposalFailed(address to, uint price);
  event ExpiredDown(uint indexed policyId);

  function createProposal(uint tokenId_, uint insuranceDuration, uint claimTrigger) external payable;

  function expiredDown(uint policyId) external;

  function proposalFailed(address beneficiaryAddress, uint insurancePremium) external;

  function createPolicy(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) external returns (uint policyId);
}
