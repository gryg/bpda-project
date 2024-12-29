require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const {
  PRIVATE_KEY,
  POLYGON_RPC_URL,
  MUMBAI_RPC_URL,
  ETHERSCAN_API_KEY,
} = process.env;

module.exports = {
  solidity: "0.8.17",
  networks: {
    polygonMumbai: {
      url: MUMBAI_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    polygonMainnet: {
      url: POLYGON_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};