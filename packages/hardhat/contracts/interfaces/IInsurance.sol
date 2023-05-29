// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IInsurance {


    function calculatePremium(
        uint tokenId,
        uint insuranceDuration
    ) external view returns (uint price);

    function createProposal(
        uint tokenId_,
        uint insuranceDuration,
        uint claimTrigger
    ) external payable;

    function createPolicy(
        uint tokenId_,
        uint insuranceDuration,
        uint insurancePremium,
        uint claimTrigger,
        address beneficiaryAddress
    ) external returns (uint policyId);

    function expiredDown(uint policyId) external returns (bool);

    function tokenIdToPolicyId(uint tokenId) external view returns (uint);

    function proposalFailed(address _to, uint price) external;

    event PolicyCreated(
        uint indexed policyId,
        uint indexed tokenId,
        uint256 indexed createTime
    );
}
