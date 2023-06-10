// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IInsurance Interface
 * @dev Interface for the Insurance contract.
 */
interface IInsurance {
    event PolicyCreated(uint indexed policyId, uint tokenId, uint startTime);
    event ProposalFailed(address to, uint price);
    event ExpiredDown(uint indexed policyId);

    /**
     * @notice Create a new insurance proposal.
     * @param tokenId_ The token ID associated with the proposal.
     * @param insuranceDuration The duration of the insurance for the proposal.
     * @param claimTrigger The trigger condition for claiming the insurance.
     */
    function createProposal(uint tokenId_, uint insuranceDuration, uint claimTrigger) external payable;

    /**
     * @notice Expire a policy and release the funds to the beneficiary.
     * @param policyId The ID of the policy to be expired.
     */
    function expiredDown(uint policyId) external;

    /**
     * @notice Handle a failed insurance proposal.
     * @param beneficiaryAddress The address of the beneficiary for the insurance.
     * @param insurancePremium The premium amount for the insurance.
     */
    function proposalFailed(address beneficiaryAddress, uint insurancePremium) external;

    /**
     * @notice Create a new insurance policy.
     * @param tokenId_ The token ID associated with the policy.
     * @param insuranceDuration The duration of the insurance for the policy.
     * @param insurancePremium The premium amount for the insurance.
     * @param claimTrigger The trigger condition for claiming the insurance.
     * @param beneficiaryAddress The address of the beneficiary for the insurance.
     * @return The ID of the created policy.
     */
    function createPolicy(
        uint tokenId_,
        uint insuranceDuration,
        uint insurancePremium,
        uint claimTrigger,
        address beneficiaryAddress
    ) external returns (uint policyId);
}
