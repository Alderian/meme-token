import hre from "hardhat";

// ARGUMENTS
// GMT	Tue Mar 19 2024 22:00:00 GMT+0000
// const TIMESTAMP_DISABLE_MAX_WALLET_TOKENS = 1710885600;
const TIMESTAMP_DISABLE_MAX_WALLET_TOKENS =
  Math.ceil(Date.now() / 1000) + 60 * 60 * 0.1;

// Percentage ot total supply that any wallet can buy until TIMESTAMP_DISABLE_MAX_WALLET_TOKENS
const maxWalletTokenPercentage = 1;

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const constructorArgs = [
    TIMESTAMP_DISABLE_MAX_WALLET_TOKENS,
    maxWalletTokenPercentage,
  ];
  const contract = await hre.ethers.deployContract(
    "MemeToken",
    constructorArgs,
  );

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log(
    "MemeToken deployed to: " + `${GREEN}${contractAddress}${RESET}\n`,
  );

  console.log(
    "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
  );
  await delay(30000); // Wait for 30 seconds before verifying the contract

  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArgs,
  });

  // Uncomment if you want to enable the `tenderly` extension
  // await hre.tenderly.verify({
  //   name: "MemeToken",
  //   address: contractAddress,
  // });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
