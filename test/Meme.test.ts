import { expect, assert } from "chai";
import hre from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { mine, time } from "@nomicfoundation/hardhat-network-helpers";
import { MemeToken } from "../typechain-types";

describe("MemeToken", function () {
  let deployerAccount: SignerWithAddress;
  let memeToken: MemeToken;

  // ARGUMENTS
  const TIMESTAMP_DISABLE_MAX_WALLET_TOKENS = Date.now() / 1000;
  // Percentage ot total supply that any wallet can buy until TIMESTAMP_DISABLE_MAX_WALLET_TOKENS
  const maxWalletTokenPercentage = 1;

  beforeEach(async function () {
    memeToken = await hre.ethers.deployContract(
      "MemeToken",
      [TIMESTAMP_DISABLE_MAX_WALLET_TOKENS, maxWalletTokenPercentage],
      deployerAccount,
    );
    await memeToken.waitForDeployment();
  });

  // it("Should return the new greeting once it's changed", async function () {
  //   expect(await memeToken.greet()).to.equal("Hello, Hardhat!");

  //   const setGreetingTx = await memeToken.setGreeting("Hola, mundo!");

  //   // Wait until the transaction is mined
  //   await setGreetingTx.wait();

  //   expect(await memeToken.greet()).to.equal("Hola, mundo!");
  // });

  // Showcase test on how to use the Hardhat network helpers library
  it("Should mine the given number of blocks", async function () {
    const blockNumberBefore = await time.latestBlock();

    await mine(100);

    assert.equal(await time.latestBlock(), blockNumberBefore + 100);
  });
});
