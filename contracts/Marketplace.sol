// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    // nftContract => tokenId => listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // marketplace fee (e.g., 2%)
    uint256 public feeBps = 200; // 200 = 2% (basis points)
    address public feeRecipient;

    // simple royalties: nftContract => tokenId => creator
    mapping(address => mapping(uint256 => address)) public creatorOf;
    uint256 public royaltyBps = 500; // 5%

    event Listed(address indexed nft, uint256 indexed tokenId, address indexed seller, uint256 price);
    event Cancelled(address indexed nft, uint256 indexed tokenId);
    event Bought(address indexed nft, uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }

    function setFee(uint256 _feeBps) external {
        // simple: only feeRecipient can change (para no complicar con Ownable)
        require(msg.sender == feeRecipient, "Only feeRecipient");
        require(_feeBps <= 1000, "Fee too high"); // max 10%
        feeBps = _feeBps;
    }

    function setRoyalty(uint256 _royaltyBps) external {
        require(msg.sender == feeRecipient, "Only feeRecipient");
        require(_royaltyBps <= 2000, "Royalty too high"); // max 20%
        royaltyBps = _royaltyBps;
    }

    function registerCreator(address nft, uint256 tokenId, address creator) external {
        // simple: allow setting creator once
        require(creatorOf[nft][tokenId] == address(0), "Creator already set");
        // only current owner of NFT can set creator initially (normalmente sería el minter)
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "Not token owner");
        creatorOf[nft][tokenId] = creator;
    }

    function list(address nft, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be > 0");
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "Not token owner");
        require(IERC721(nft).getApproved(tokenId) == address(this)
            || IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nft][tokenId] = Listing({ seller: msg.sender, price: price });
        emit Listed(nft, tokenId, msg.sender, price);
    }

    function cancel(address nft, uint256 tokenId) external {
        Listing memory l = listings[nft][tokenId];
        require(l.seller != address(0), "Not listed");
        require(l.seller == msg.sender, "Only seller");
        delete listings[nft][tokenId];
        emit Cancelled(nft, tokenId);
    }

    function buy(address nft, uint256 tokenId) external payable nonReentrant {
        Listing memory l = listings[nft][tokenId];
        require(l.seller != address(0), "Not listed");
        require(msg.value == l.price, "Wrong price");

        // effects first
        delete listings[nft][tokenId];

        // interactions
        IERC721(nft).safeTransferFrom(l.seller, msg.sender, tokenId);

        uint256 fee = (msg.value * feeBps) / 10_000;
        uint256 royalty = 0;

        address creator = creatorOf[nft][tokenId];
        if (creator != address(0)) {
            royalty = (msg.value * royaltyBps) / 10_000;
        }

        uint256 sellerAmount = msg.value - fee - royalty;

        if (fee > 0) payable(feeRecipient).transfer(fee);
        if (royalty > 0) payable(creator).transfer(royalty);
        payable(l.seller).transfer(sellerAmount);

        emit Bought(nft, tokenId, msg.sender, msg.value);
    }
}
