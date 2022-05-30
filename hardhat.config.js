require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

const { API_URL, PRIVATE_KEY, MAIN_API_URL } = process.env;
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
      }
    }
  },
  paths: {
    artifacts: './src/artifacts'
  },
  defaultNetwork: "polygon_testnet",
  networks: {
    hardhat: {},
    polygon_testnet: {
      url: API_URL,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 7000000,
      gasPrice: 60000000000
    },
    polygon_mainnet: {
      url: MAIN_API_URL,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 7000000,
      gasPrice: 60000000000
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: "NQCKTCEN5KF1FS68PYR1EZ84F87PX8FXJ6",
      polygon: "NQCKTCEN5KF1FS68PYR1EZ84F87PX8FXJ6"
    }
  }
};
