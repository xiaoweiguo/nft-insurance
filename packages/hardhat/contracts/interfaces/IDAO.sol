// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDAO {
    function createProposal(
        uint tokenId_,
        uint insuranceDuration,
        uint insurancePremium,
        uint claimTrigger,
        address beneficiaryAddress
    ) external;

    function triggerInsurance(address _to, uint amount) external;
}
