// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./insurance/interfaces/ILiquidityPool.sol";
import "./insurance/interfaces/IDAO.sol";

contract LiquidityPool is ILiquidityPool, Ownable {
  IDAO DAO;

  // Fallback function to receive ETH
  receive() external payable {
    emit Received(block.timestamp, msg.value);
  }

  // Modifier to restrict access to only the DAO contract
  modifier onlyDAO() {
    require(msg.sender == address(DAO), "Only DAO can call this function.");
    _;
  }

  // Sets the address of the DAO contract
  function setDAOAddress(address DAOAddress) external onlyOwner {
    DAO = IDAO(DAOAddress);
    renounceOwnership();
  }

  // Sends ETH to a specified address, callable only by the DAO contract
  function sendEth(address payable _to, uint amount) external onlyDAO {
    require(address(this).balance >= amount, "Not enough balance.");
    _to.transfer(amount);
    emit Sent(_to, amount);
  }

  // Returns the current balance of the liquidity pool
  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  // Returns the address of the DAO contract
  function getDAOAddress() external view returns (address) {
    return address(DAO);
  }
}
