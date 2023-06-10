// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title ILiquidityPool Interface
 * @dev Interface for the LiquidityPool contract.
 */
interface ILiquidityPool {
    event Received(uint timestamp, uint amount);
    event Sent(address indexed to, uint amount);

    /**
     * @notice Send ETH to a specified address.
     * @param _to The address to send ETH to.
     * @param amount The amount of ETH to send.
     */
    function sendEth(address payable _to, uint amount) external;
}
