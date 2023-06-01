// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IDAO.sol";

contract LiquidityPool is ILiquidityPool {
    IDAO DAO;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        emit Received(block.timestamp, msg.value);
    }

    modifier onlyDAO() {
        require(msg.sender == address(DAO), "Only DAO can call this function.");
        _;
    }

    function setDAOAddress(address DAOAddress) external {
        require(msg.sender == admin, "only admin can call");
        DAO = IDAO(DAOAddress);
        admin = address(0);
    }

    function sendEth(address payable _to, uint amount) external onlyDAO {
        require(address(this).balance >= amount, "Not enough balance.");
        _to.transfer(amount);
        emit Sent(_to, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getDAOAddress() external view returns (address) {
        return address(DAO);
    }
}
