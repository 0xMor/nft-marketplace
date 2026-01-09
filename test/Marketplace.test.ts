const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Marketplace", function () {
    it("lists and buys with fee + royalty", async function () {
        const [deployer, seller, buyer, feeRecipient, creator] = await ethers.getSigners();

        const NFT = await ethers.getContractFactory("MyNFT");
        const nft = await NFT.connect(deployer).deploy();
        await nft.waitForDeployment();

        const Market = await ethers.getContractFactory("Marketplace");
        const market = await Market.connect(deployer).deploy(await feeRecipient.getAddress());
        await market.waitForDeployment();

        // mint NFT to seller
        await nft.connect(deployer).mint(await seller.getAddress());
        const tokenId = 0;

        // seller approves marketplace
        await nft.connect(seller).approve(await market.getAddress(), tokenId);

        // set creator (royalty recipient)
        await market.connect(seller).registerCreator(await nft.getAddress(), tokenId, await creator.getAddress());

        // list
        const price = ethers.parseEther("1");
        await market.connect(seller).list(await nft.getAddress(), tokenId, price);

        // buy
        await expect(
            market.connect(buyer).buy(await nft.getAddress(), tokenId, { value: price })
        ).to.emit(market, "Bought");

        // ownership transferred
        expect(await nft.ownerOf(tokenId)).to.equal(await buyer.getAddress());
    });

    it("prevents buying with wrong price", async function () {
        const [deployer, seller, buyer, feeRecipient] = await ethers.getSigners();

        const NFT = await ethers.getContractFactory("MyNFT");
        const nft = await NFT.connect(deployer).deploy();
        await nft.waitForDeployment();

        const Market = await ethers.getContractFactory("Marketplace");
        const market = await Market.connect(deployer).deploy(await feeRecipient.getAddress());
        await market.waitForDeployment();

        await nft.connect(deployer).mint(await seller.getAddress());
        const tokenId = 0;

        await nft.connect(seller).approve(await market.getAddress(), tokenId);

        const price = ethers.parseEther("1");
        await market.connect(seller).list(await nft.getAddress(), tokenId, price);

        await expect(
            market.connect(buyer).buy(await nft.getAddress(), tokenId, { value: ethers.parseEther("0.5") })
        ).to.be.revertedWith("Wrong price");
    });
});
