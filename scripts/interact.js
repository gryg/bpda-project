const hre = require("hardhat");

async function main() {
  const contractAddress = "0x[YourContractAddress]"; // Replace with your deployed contract address
  const BettingContract = await hre.ethers.getContractFactory("BettingContract");
  const bettingContract = BettingContract.attach(contractAddress);

  const [signer] = await hre.ethers.getSigners();

  // Place a bet
  const tx = await bettingContract.connect(signer).placeBet(0, {
    value: hre.ethers.utils.parseEther("0.1"),
  });
  await tx.wait();
  console.log("Bet placed!");

  // Request the outcome after the betting deadline
  // const requestTx = await bettingContract.requestOutcome();
  // await requestTx.wait();
  // console.log("Outcome requested!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });