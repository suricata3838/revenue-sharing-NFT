require ("@nomiclabs/hardhat-ethers");
require ("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');
require("hardhat-gas-reporter");
require("dotenv").config();
const {
  ETH_API, 
  POLYGON_API, 
  MUMBAI_API,
  ETHSCAN_APIKEY, 
  POLYGONSCAN_APIKEY, 
  GOERLI_API, 
  PRIVKEY 
} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "goerli",
  networks: {
    hardhat: {
      forking: {
        url: 'https://polygon-mumbai.infura.io/v3/b46167d4ce7e4190bff6c46f2eb6363d'
      }
    },
    mainnet: {
      url: ETH_API,
      accounts: [`0x${PRIVKEY}`]
    },
    goerli: {
      url: GOERLI_API,
      accounts: [`0x${PRIVKEY}`]
    },
    polygon: {
      url: POLYGON_API,
      accounts: [`0x${PRIVKEY}`]      
    },
    polygonMumbai: {
      url: MUMBAI_API,
      accounts: [`0x${PRIVKEY}`]
    }
  },
  solidity: "0.8.9",
  settings: {
    optimizer: {
      enabled: true,
      runs: 150,
    },
  },
  paths: {
    sources: './contracts/active'
  },
  etherscan: {
    apiKey: {
      mainnet: ETHSCAN_APIKEY,
      goerli: ETHSCAN_APIKEY,
      polygon: POLYGONSCAN_APIKEY,
      polygonMumbai: POLYGONSCAN_APIKEY
    }
  }
};
