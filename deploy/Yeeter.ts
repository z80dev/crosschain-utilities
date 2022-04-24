import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const BEETS_VAULT = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce";
const BAL_POLY_VAULT = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

const STG_FTM_ROUTER = "0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6";
const STG_POLY_ROUTER = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd";
const STG_AVAX_ROUTER = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd";

const func: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  console.log(deployer);

  const { address } = await deploy("VaultYeeter", {
    from: deployer,
    args: [STG_FTM_ROUTER, BEETS_VAULT],
  });

  console.log(`VaultYeeter deployed to ${address}`);
};

export default func;
