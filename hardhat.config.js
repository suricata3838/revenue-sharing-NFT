require ("@nomiclabs/hardhat-ethers");
require ("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
const { APIKEY, PRIVKEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "rinkeby",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/5Sz4-6bji6Wo4xuI_1JYNT_GZg9b40JY",
      accounts: [`0x${PRIVKEY}`]
    }
  },
  solidity: "0.8.9",
  etherscan: {
    apiKey: {
      polygon: "W38RH21ZF3K4MA6MJU34V5WA5D3B72BV88",
      rinkeby: "PCBEMJAJZDDPQHVW15ZK6Y6NZUS2D3X8Y8"
    }
  },

};
