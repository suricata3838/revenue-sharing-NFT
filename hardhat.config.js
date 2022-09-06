require ("@nomiclabs/hardhat-ethers");
require ("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
const { POLYGON_APIKEY, RINKEBY_API, RINKEBY_APIKEY, PRIVKEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "rinkeby",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: RINKEBY_API,
      accounts: [`0x${PRIVKEY}`]
    }
  },
  solidity: "0.8.9",
  etherscan: {
    apiKey: {
      polygon: POLYGON_APIKEY,
      rinkeby: RINKEBY_APIKEY
    }
  }
};
