import "dotenv/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-solhint";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@tenderly/hardhat-tenderly";
import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "hardhat-spdx-license-identifier";
import "hardhat-watcher";
import "solidity-coverage";

import { HardhatUserConfig, task } from "hardhat/config";

import { removeConsoleLog } from "hardhat-preprocessor";

let accounts;

if (process.env.PRIVATE_KEY) {
  accounts = [process.env.PRIVATE_KEY];
} else {
  accounts = {
    mnemonic:
      process.env.MNEMONIC ||
      "test test test test test test test test test test test junk",
  };
}

const STG_FTM_ROUTER = "0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6";
const STG_POLY_ROUTER = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd";

const YEETER_ADDR = "0xB616Cd0208a0c21B043E8B4c10Bd2e8ec3a3Cc7C";

task("quote", "Get quote from fantom to polygon", async (args, { ethers }) => {
  const router = await ethers.getContractAt("IStargateRouter", STG_FTM_ROUTER);
  const payload = ethers.utils.defaultAbiCoder.encode(["uint256"], [1]);
  const quoteData = await router.quoteLayerZeroFee(
    9,                 // destination chainId
    1,               // function type: see Bridge.sol for all types
    ethers.utils.defaultAbiCoder.encode(["tuple(address[], uint256, bytes32, address, address, address)"], ["0xB616Cd0208a0c21B043E8B4c10Bd2e8ec3a3Cc7C"]),                  // destination of tokens
    payload,                         // payload, using abi.encode()
    {
      dstGasForCall: 100000,       // extra gas, if calling smart contract,
      dstNativeAmount: 100,     // amount of dust dropped in destination wallet
      dstNativeAddr: "0xB616Cd0208a0c21B043E8B4c10Bd2e8ec3a3Cc7C" // destination wallet for dust
    }
)
  console.log(quoteData);
});

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, { ethers }) => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

const config: HardhatUserConfig = {
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      opera: process.env.FTMSCAN_API_KEY,
    },
  },
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    currency: "USD",
    enabled: process.env.REPORT_GAS === "true",
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    alice: {
      default: 1,
    },
    bob: {
      default: 2,
    },
    carol: {
      default: 3,
    },
  },
  networks: {
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ["local"],
    },
    hardhat: {
      forking: {
        enabled: process.env.FORKING === "true",
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      },
      live: false,
      saveDeployments: true,
      tags: ["test", "local"],
    },
    ethereum: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts,
      chainId: 1,
      live: true,
      saveDeployments: true,
      tags: ["mainnet"],
      hardfork: process.env.CODE_COVERAGE ? "berlin" : "london",
    },
    opera: {
      url: 'https://rpc.ftm.tools/',
      accounts,
      saveDeployments: true,
      tags: ["fantom"]
    },
    polygon: {
      url: 'https://polygon-rpc.com/',
      accounts,
      saveDeployments: true,
      tags: ["polygon", "matic"]
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts,
      chainId: 3,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts,
      chainId: 5,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
    },
  },
  preprocess: {
    eachLine: removeConsoleLog(
      (bre) =>
        bre.network.name !== "hardhat" && bre.network.name !== "localhost"
    ),
  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
  tenderly: {
    project: String(process.env.TENDERLY_PROJECT),
    username: String(process.env.TENDERLY_USERNAME),
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  watcher: {
    compile: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
    },
  },
};

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
export default config;
