// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/Address.sol";

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external;
}

contract BaseERC20WithCallback is ERC20 {
    using Address for address;

    address public owner;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function transferWithCallback(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        if (to.code.length > 0) {
            try ITokenReceiver(to).tokensReceived(msg.sender, amount) {
                // ok
            } catch {
                revert("Receiver contract does not implement tokensReceived");
            }
        }

        return true;
    }
}
