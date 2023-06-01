// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDAO {
  event Vote(address indexed voter, uint indexed proposalId, uint voteTime);
  event CreateProposal(uint indexed proposalId, uint tokenId_, address beneficiaryAddress, uint createTime);
  event Withdraw(address indexed user, uint stakingAmount, uint timestamp);
  event Stake(address indexed user, uint stakingAmount, uint timestamp);

  function createProposal(
    uint tokenId_,
    uint insuranceDuration,
    uint insurancePremium,
    uint claimTrigger,
    address beneficiaryAddress
  ) external;

  function triggerInsurance(address _to, uint amount) external;
}
