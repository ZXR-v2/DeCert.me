// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";


contract Bank{
    address private owner;
    mapping(address => uint256) public balances;
    uint256 public total;
    address[3] private top3;

    event Deposit(address indexed user, address indexed from, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed recipient, uint256 amount, uint256 remainingBalance);
    event LeaderboardUpdated(address[3] top3);
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        top3 = [address(0), address(0), address(0)];
    }

    /**
    **/
    function deposit(address payable _to) external payable  {
        uint256 _amount = msg.value;
        balances[_to] += _amount;
        total += _amount;
        uint256 newBalance = balances[_to];

        // Skip if already in top3
        if (_to == top3[0] || _to == top3[1] ||_to == top3[2]) {
            emit Deposit(_to, msg.sender, _amount, newBalance);
            return;
        }

        // Update leaderboard
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

    function withdraw(uint256 _amount) public isOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(total > 0, "No funds available");

        uint256 withdrawAmount = (_amount > total) ? total : _amount;
        total -= withdrawAmount;

        (bool success, ) = payable(owner).call{value: withdrawAmount}("");
        require(success, "Transfer failed");

        emit Withdraw(owner, withdrawAmount, total);
    }
    
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        require(newOwner != address(0), "New owner should not be the zero address");
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

}
