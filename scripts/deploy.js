const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const BettingContract = await hre.ethers.getContractFactory("BettingContract");

  // Set deployment parameters
  const bettingDeadline = Math.floor(Date.now() / 1000) + 3600 * 24; // 24 hours from now
  const oracleAddress = "0x[OptimisticOracleV2AddressOnPolygon]"; // Replace with the actual address
  const identifier = hre.ethers.utils.formatBytes32String("YES_OR_NO_QUERY");
  const ancillaryData = hre.ethers.utils.toUtf8Bytes("Will event X happen?");
  const rewardTokenAddress = "0x[UMA_ERC20_Token_Address]"; // Replace with the actual token address

  const bettingContract = await BettingContract.deploy(
    bettingDeadline,
    oracleAddress,
    identifier,
    ancillaryData,
    rewardTokenAddress
  );

  await bettingContract.deployed();

  console.log("BettingContract deployed to:", bettingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });