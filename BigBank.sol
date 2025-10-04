// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // <-- Required for sendValue


interface IBank {
    function deposit(address payable _to) external payable;
    function withdraw(uint256 amount) external;
}

contract Bank is IBank, Ownable{
    // address private owner;
    using Address for address; // <-- Enable sendValue for all addresses
    mapping(address => uint256) public balances;
    uint256 public total;
    address[3] private top3;

    event Deposit(address indexed user, address indexed from, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed recipient, uint256 amount, uint256 remainingBalance);
    event LeaderboardUpdated(address[3] top3);
    // event for EVM logging

    constructor(address initialOwner) Ownable(initialOwner) {
        top3 = [address(0), address(0), address(0)];
    }

    /**
    **/
    function deposit(address payable _to) virtual external payable  {
        _depositLogic(_to, msg.value);
    }


    // Internal function for shared logic
    function _depositLogic(address payable _to, uint256 _amount) internal {
        balances[_to] += _amount;
        total += _amount;
        uint256 newBalance = balances[_to];

        if (_to == top3[0] || _to == top3[1] || _to == top3[2]) {
            emit Deposit(_to, msg.sender, _amount, newBalance);
            return;
        }

        if (newBalance > balances[top3[0]]) {
            top3[2] = top3[1];
            top3[1] = top3[0];
            top3[0] = _to;
        } else if (newBalance > balances[top3[1]]) {
            top3[2] = top3[1];
            top3[1] = _to;
        } else if (newBalance > balances[top3[2]]) {
            top3[2] = _to;
        }
        emit Deposit(_to, msg.sender, _amount, newBalance);
        emit LeaderboardUpdated(top3);
    }


    function withdraw(uint256 _amount) virtual public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(total > 0, "No funds available");

        uint256 withdrawAmount = (_amount > total) ? total : _amount;
        total -= withdrawAmount;
        // Transfer the funds to the owner
        Address.sendValue(payable(owner()), _amount);// <-- Add `payable()`

        emit Withdraw(owner(), withdrawAmount, total);
    }
}


contract BigBank is Bank{
    constructor (address _owner) Bank(_owner) {}
    modifier largerDeposit(uint256 _amount){
        require(_amount > 0.001 ether, "Deposit must be larger than 0.001 ether");
        _; 
    }

    // Override the deposit function to include the largerDeposit modifier
    function deposit(address payable _to) override external payable largerDeposit(msg.value){
        _depositLogic(_to, msg.value);
    }

}

contract Admin is Ownable{
    using Address for address;
    constructor(address _owner) Ownable(_owner){}
    function adminWithdraw(IBank bank, uint256 _amount) external payable onlyOwner{
        bank.withdraw(_amount);
    }

    receive() external payable { }

}
