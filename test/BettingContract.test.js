const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BettingContract", function () {
  let BettingContract, bettingContract, owner, addr1, addr2;

  beforeEach(async function () {
    BettingContract = await ethers.getContractFactory("BettingContract");
    [owner, addr1, addr2, _] = await ethers.getSigners();

    // Mock parameters
    const bettingDeadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const oracleAddress = owner.address; // Mock oracle address
    const identifier = ethers.utils.formatBytes32String("TEST_QUERY");
    const ancillaryData = ethers.utils.toUtf8Bytes("Test ancillary data");
    const rewardTokenAddress = owner.address; // Mock token address

    bettingContract = await BettingContract.deploy(
      bettingDeadline,
      oracleAddress,
      identifier,
      ancillaryData,
      rewardTokenAddress
    );
    await bettingContract.deployed();
  });

  it("Should allow users to place bets", async function () {
    await bettingContract.connect(addr1).placeBet(0, { value: ethers.utils.parseEther("1") });
    const bet = await bettingContract.bets(addr1.address);
    expect(bet.amount).to.equal(ethers.utils.parseEther("1"));
    expect(bet.option).to.equal(0);
  });

  // Add more test cases for requesting outcome, settling, and claiming winnings
});