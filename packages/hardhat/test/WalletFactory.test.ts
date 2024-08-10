import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { EventLog } from "ethers";
import { WalletFactoryContract } from "../typechain-types";

describe("WalletFactory", function () {
  // We define a fixture to reuse the same setup in every test.

  let walletFactory: WalletFactoryContract;
  let owner: HardhatEthersSigner;

  before(async () => {
    owner = (await ethers.getSigners())[0];
    const WalletFactoryContract = await ethers.getContractFactory("WalletFactoryContract");

    // We deploy the contract
    walletFactory = await WalletFactoryContract.deploy();
    await walletFactory.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should check the owner", async function () {
      expect(await walletFactory.owner()).to.equal(owner.address);
    });
    it("Should validate the address for a wallet contract before to deploy and after", async function () {
      const addressBefore = await walletFactory.predictWalletAddress("0x");
      // create wallet and get the address from the result of the transaction
      const tx = await walletFactory.createWallet("0x");
      const txResult = await tx.wait();
      // get the address from the txResult
      const log: EventLog = txResult?.logs[0] as EventLog;
      const addressAfter = log.args[0];

      expect(addressBefore).to.equal(addressAfter);
    });
    it("Should send to the wallet contract 2 ethers", async function () {
      const address = await walletFactory.predictWalletAddress("0x");
      // check the address is a contract walletContract
      const valid = await walletFactory.isContractDeployed(address);
      expect(valid).to.equal(true);
      // check any other address is not a contract walletContract
      const valid2 = await walletFactory.isContractDeployed(owner.address);
      expect(valid2).to.equal(false);
      // check another address is not a contract walletContract
      const address2 = await walletFactory.predictWalletAddress("54");
      const valid3 = await walletFactory.isContractDeployed(address2);
      expect(valid3).to.equal(false);
      const tx = await owner.sendTransaction({ to: address, value: ethers.parseEther("2") });
      await tx.wait();
      const balance = await ethers.provider.getBalance(address);
      expect(balance).to.equal(ethers.parseEther("2"));
    });
    it("Should withdraw all coins to a wallet called sarah", async function () {
      const address = await walletFactory.predictWalletAddress("0x");
      const sarah = ethers.Wallet.createRandom().address;
      const tx = await walletFactory.withdrawAll([address], sarah);
      await tx.wait();
      const balance = await ethers.provider.getBalance(sarah);
      expect(balance).to.equal(ethers.parseEther("2"));
    });
    it("Should revert if the wallet is not the owner", async function () {
      const address = await walletFactory.predictWalletAddress("0x");
      const sarah = await (await ethers.getSigners())[1];
      const walletFactoryWithSarah = walletFactory.connect(sarah);
      await expect(walletFactoryWithSarah.withdrawAll([address], sarah.address)).to.be.revertedWith(
        "Only owner can call this function",
      );
    });
  });
});
