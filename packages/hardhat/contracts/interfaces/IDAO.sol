// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IDAO Interface
 * @dev Interface for the DAO contract.
 */
interface IDAO {
    event Vote(address indexed voter, uint indexed proposalId, uint voteTime);
    event CreateProposal(uint indexed proposalId, uint tokenId_, address beneficiaryAddress, uint createTime);
    event Withdraw(address indexed user, uint stakingAmount, uint timestamp);
    event Stake(address indexed user, uint stakingAmount, uint timestamp);

    /**
     * @notice Create a new proposal.
     * @param tokenId_ The token ID associated with the proposal.
     * @param insuranceDuration The duration of the insurance for the proposal.
     * @param insurancePremium The premium amount for the insurance.
     * @param claimTrigger The trigger condition for claiming the insurance.
     * @param beneficiaryAddress The address of the beneficiary for the insurance.
     */
    function createProposal(
        uint tokenId_,
        uint insuranceDuration,
        uint insurancePremium,
        uint claimTrigger,
        address beneficiaryAddress
    ) external;

    /**
     * @notice Trigger the insurance by transferring the funds to the specified address.
     * @param _to The address to transfer the insurance funds to.
     * @param amount The amount of insurance funds to transfer.
     */
    function triggerInsurance(address _to, uint amount) external;
}
