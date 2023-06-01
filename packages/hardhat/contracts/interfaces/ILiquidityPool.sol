// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ILiquidityPool {
  event Received(uint, uint);
  event Sent(address, uint);

  function sendEth(address payable _to, uint amount) external;
}
