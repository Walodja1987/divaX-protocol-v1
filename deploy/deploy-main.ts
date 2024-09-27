/**
 * Script for a single deployment of the DIVAX system on main chain (Ethereum)
 * Run via `pnpm deploy/deploy-main.ts --network mumbai`
 */

import { ethers as hardhatEthers } from "hardhat"; // available in global scope, added for explicitness } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
    CollateralPoolFactory,
    ProductTokenFactory,
    MOVE
  } from "../typechain-types";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

function delay(ms: number) {
return new Promise((resolve) => setTimeout(resolve, ms));
}

export const deployMain = async (hre: HardhatRuntimeEnvironment): Promise<[string, string, string, string]> => {
    // Get the private key from the configured network
    // This assumes that a private key is configured for the selected network
    const accounts = hre.network.config.accounts;
    if (!Array.isArray(accounts)) {
        throw new Error(
        `No private key configured for network ${hre.network.name}`,
        );
    }
    const PRIVATE_KEY = accounts[0];
    if (typeof PRIVATE_KEY !== "string") {
        throw new Error(
        `No private key configured for network ${hre.network.name}`,
        );
    }

    const wallet = new hardhatEthers.Wallet(PRIVATE_KEY);
    const deployer = new hardhatEthers.Deployer(hre, wallet);
  
    // const [deployer] = await hardhatEthers.getSigners();
    console.log("Deployer address: " + deployer.address);

    // Deploy product token factory
    const constructorArgsProductTokenFactory = [];
    const productTokenFactory: ProductTokenFactory =
    await hardhatEthers.deployContract("ProductTokenFactory", constructorArgsProductTokenFactory, {
        from: deployer,
    });
    await productTokenFactory.waitForDeployment();
    const productTokenFactoryAddress = productTokenFactory.target;

    console.log("ProductTokenFactory deployed to: " + `${GREEN}${productTokenFactoryAddress}${RESET}\n`);

    // Deploy MOVE
    const constructorArgsMove = [productTokenFactory.target];
    const move: MOVE =
    await hardhatEthers.deployContract("MOVE", constructorArgsMove, {
        from: deployer,
    });
    await move.waitForDeployment();
    const moveAddress = await move.target;

    console.log("MOVE deployed to: " + `${GREEN}${moveAddress}${RESET}\n`);

    // Deploy collateral pool
    const constructorArgsCollateralPoolFactory = [];
    const collateralPoolFactory: CollateralPoolFactory =
    await hardhatEthers.deployContract("CollateralPoolFactory", constructorArgsCollateralPoolFactory, {
        from: deployer,
    });
    await collateralPoolFactory.waitForDeployment();
    const collateralPoolFactoryAddress = await collateralPoolFactory.target;

    console.log("CollateralPoolFactory deployed to: " + `${GREEN}${collateralPoolFactoryAddress}${RESET}\n`);

    console.log(
        "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
    );
    await delay(30000); // Wait for 30 seconds before verifying the contract

    await hre.run("verify:verify", {
        address: productTokenFactoryAddress,
        constructorArguments: constructorArgsProductTokenFactory,
    });

    await hre.run("verify:verify", {
        address: moveAddress,
        constructorArguments: constructorArgsMove,
    });

    await hre.run("verify:verify", {
        address: collateralPoolFactoryAddress,
        constructorArguments: constructorArgsCollateralPoolFactory,
    });
  
  return [    
    deployer.address,
    productTokenFactoryAddress,
    moveAddress,
    collateralPoolFactoryAddress
  ];
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployMain()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
