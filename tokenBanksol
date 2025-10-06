// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // <-- Required for sendValue
import "contracts/baseERC20.sol";

contract TokenBank{
    using Address for address; // <-- Enable sendValue for all addresses
    mapping(address => mapping(address => uint256)) public deposits; // token合约地址——》存款地址——〉存款
    event Deposit(address indexed token, address indexed to, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed recipient, uint256 amount, uint256 remainingBalance);
    
    function deposit(address _token, address _to, uint256 _amount) external{
        require(_amount > 0, "Amount must be greater than zero");
        BaseERC20 baseERC20 = BaseERC20(_token);
        // 采用先授权，再去转账的方式；
        baseERC20.approve(address(this), _amount);
        baseERC20.transferFrom(msg.sender, address(this), _amount);
        deposits[_token][_to] += _amount;
        emit Deposit(_token, _to, _amount, deposits[_token][_to]);
        console.log("deposit success");
    }

    function withdraw(address _token, uint256 _amount) external{
        require(_amount > 0, "Amount must be greater than zero");
        require(deposits[_token][msg.sender] >= _amount, "Insufficient funds");
        BaseERC20 baseERC20 = BaseERC20(_token);
        baseERC20.transfer(msg.sender, _amount);
        deposits[_token][msg.sender] -= _amount;
        emit Withdraw(msg.sender, _amount, deposits[_token][msg.sender]);
    }
}
