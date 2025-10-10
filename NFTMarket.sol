// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

/**
 * @dev 接口：带回调功能的 ERC20 接收者
 */
interface ITokenReceiver {
    function tokensReceived(
        address from,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        string calldata message
    ) external;
}

/**
 * @dev 带回调的 ERC20 代币
 */
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

    /// @dev 发行代币
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 扩展转账函数，支持 tokensReceived 回调
     * @param to 接收者（可为合约地址）
     * @param nftAddress 如果用于购买NFT，这里传入NFT合约地址
     * @param tokenId NFT编号
     * @param amount 转账金额
     * @param message 附加消息（例如“buy NFT”）
     */
    function transferWithCallback(
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        string calldata message
    ) external returns (bool) {
        _transfer(msg.sender, to, amount);

        // 如果接收方是合约地址，则尝试回调
        if (to.code.length > 0) {
            try ITokenReceiver(to).tokensReceived(msg.sender, nftAddress, tokenId, amount, message) {
                // 成功则继续
            } catch {
                revert("Receiver contract does not implement tokensReceived");
            }
        }

        return true;
    }
}

/**
 * @dev NFT市场：支持用 ERC20 购买 NFT
 */
contract NFTMarket is ITokenReceiver {
    using Address for address;

    /// NFT地址 => tokenId => 拥有者
    mapping(address => mapping(uint256 => address)) private _owners;

    /// NFT地址 => tokenId => 出售价
    mapping(address => mapping(uint256 => uint256)) private _prices;

    /// 支付用代币
    address public immutable currency;

    event Listed(address indexed owner, address indexed nft, uint256 indexed tokenId, uint256 price);
    event Purchased(address indexed buyer, address indexed nft, uint256 indexed tokenId, uint256 amount);

    constructor(address _currency) {
        require(_currency != address(0), "Invalid token address");
        currency = _currency;
    }

    /**
     * @dev 上架NFT
     */
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);

        require(owner == msg.sender, "Not NFT owner");
        require(price > 0, "Price must be > 0");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Market not approved"
        );

        _owners[nftAddress][tokenId] = owner;
        _prices[nftAddress][tokenId] = price;

        emit Listed(owner, nftAddress, tokenId, price);
    }

    /**
     * @dev 用户主动购买NFT（非callback方式）
     */
    function buyNFT(address nftAddress, uint256 tokenId) external {
        uint256 price = _prices[nftAddress][tokenId];
        address seller = _owners[nftAddress][tokenId];

        require(seller != address(0), "NFT not listed");
        require(price > 0, "Invalid price");

        // 用户支付ERC20
        require(ERC20(currency).transferFrom(msg.sender, seller, price), "Token transfer failed");

        // 转移NFT
        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId);

        // 清除挂单
        _owners[nftAddress][tokenId] = address(0);
        _prices[nftAddress][tokenId] = 0;

        emit Purchased(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @dev ERC20 回调函数：当用户使用 transferWithCallback 支付时触发购买逻辑
     */
    function tokensReceived(
        address from,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        string calldata message
    ) external override {
        address token = msg.sender;
        require(token == currency, "Invalid payment token");

        address seller = _owners[nftAddress][tokenId];
        uint256 price = _prices[nftAddress][tokenId];

        require(seller != address(0), "NFT not listed");
        require(amount >= price, "Amount too low");

        // 转NFT
        IERC721(nftAddress).safeTransferFrom(seller, from, tokenId);

        // 支付给卖家
        ERC20(token).transfer(seller, price);

        // 清除挂单
        _owners[nftAddress][tokenId] = address(0);
        _prices[nftAddress][tokenId] = 0;

        emit Purchased(from, nftAddress, tokenId, amount);

        // console.log("NFTMarket: tokensReceived success from", from, "amount", amount, "message", message);
    }

    /// @dev 查询价格
    function getPrice(address nftAddress, uint256 tokenId) external view returns (uint256) {
        return _prices[nftAddress][tokenId];
    }
}
