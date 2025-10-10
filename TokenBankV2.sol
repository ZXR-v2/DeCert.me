// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "contracts/TokenBank.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface IExtendedERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenBankV2 is TokenBank {
    using Address for address;

    /**
     * @dev Hook 回调函数：当 ERC20 的 transferWithCallback 调用时被触发
     */
    function tokensReceived(address from, uint256 amount) external {
        address token = msg.sender; // msg.sender 就是 ERC20 合约地址
        require(token.code.length > 0, "Only tokens can trigger callback");
        require(amount > 0, "Invalid amount");

        deposits[token][from] += amount;
        emit Deposit(token, from, amount, deposits[token][from]);

        console.log("TokenBankV2: tokensReceived success from", from, "amount", amount);
    }
}
