require ("@nomiclabs/hardhat-ethers");
require ("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
const { GOERLI_APIKEY, ETHSCAN_APIKEY, GOERLI_API, PRIVKEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "goerli",
  networks: {
    hardhat: {
    },
    goerli: {
      url: GOERLI_API,
      accounts: [`0x${PRIVKEY}`]
    }
  },
  solidity: "0.8.9",
  etherscan: {
    apiKey: {
      goerli: ETHSCAN_APIKEY
    }
  }
};
