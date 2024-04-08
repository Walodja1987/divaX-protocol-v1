import { expect, assert } from "chai";
import { ethers, ContractEvent } from "ethers";
import { ethers as hardhatEthers } from "hardhat"; // available in global scope, added for explicitness
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
  mine,
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-network-helpers";
import { SetupOutput } from "../constants/types";
import { getExpiryTime } from "../utils/helper";
import { vars } from "hardhat/config";
import {
  CollateralPool,
  CollateralPoolFactory,
  MockERC20,
  MockERC721,
  ProductToken,
  ProductTokenFactory,
  MOVE
} from "../typechain-types";

describe("CollateralPool", function () {
  describe("Initialization", function () {
    it("Should create a collateral pool and initialize the parameters correctly", async () => {
      const signers = await hardhatEthers.getSigners();
      const issuer = signers[0];

      // Generate the collateral token and send it to the issuer's account
      const collateralTokenDecimals = 18;
      const collateralToken: MockERC20 = await hardhatEthers.deployContract(
        "MockERC20",
        [
          "collateralMockToken", // name
          "CMT", // symbol
          ethers.parseUnits("10000", collateralTokenDecimals), // totalSupply
          issuer.address, // recipient
          collateralTokenDecimals, // decimals
          0, // feePct
        ],
        {
          from: issuer,
        },
      );
      await collateralToken.waitForDeployment();

      // @todo move below in a deploy script
      // Deploy product token factory
      const productTokenFactory: ProductTokenFactory =
        await hardhatEthers.deployContract("ProductTokenFactory", [], {
          from: issuer,
        });
      await productTokenFactory.waitForDeployment();

      // Deploy MOVE
      const move: MOVE =
        await hardhatEthers.deployContract("MOVE", [productTokenFactory.target], {
          from: issuer,
        });
      await move.waitForDeployment();

      // Deploy collateral pool
      const collateralPoolFactory: CollateralPoolFactory =
        await hardhatEthers.deployContract("CollateralPoolFactory", [], {
          from: issuer,
        });
      await collateralPoolFactory.waitForDeployment();

      await collateralPoolFactory.connect(issuer).createCollateralPool(collateralToken.target, move.target);

      // Get collateral pool address
      const collateralPoolAddress = (await collateralPoolFactory.getCollateralPools()).at(-1);

      const collateralPool: CollateralPool = await hardhatEthers.getContractAt(
        "CollateralPool",
        collateralPoolAddress,
      );

      expect(await collateralPool.getManager()).to.eq(issuer.address);
      expect(await collateralPool.getCollateralToken()).to.eq(collateralToken.target);
      expect(await collateralPool.getPermissionedContract()).to.eq(move.target);
      
    });



    // // Test setup function
    // async function setup(): Promise<SetupOutput> {
    //   // Get the Signers
    //   const signers = await hardhatEthers.getSigners();
    //   const issuer = signers[0];
    //   const acc2 = signers[1];
    //   const acc3 = signers[2];

    //   // Generate the voucher token and send it to the issuer's account
    //   const voucherTokenDecimals = 18;
    //   const voucherToken: MockERC20 = await hardhatEthers.deployContract(
    //     "MockERC20",
    //     [
    //       "voucherMockToken", // name
    //       "VMT", // symbol
    //       ethers.parseUnits("10000", voucherTokenDecimals), // totalSupply
    //       issuer.address, // recipient
    //       voucherTokenDecimals, // decimals
    //       0, // feePct
    //     ],
    //     {
    //       from: issuer,
    //     },
    //   );
    //   await voucherToken.waitForDeployment();

    //   // Deploy DIVA Voucher factory contract
    //   const divaVoucherFactory: DIVAVoucherFactory =
    //     await hardhatEthers.deployContract(
    //       "DIVAVoucherFactory",
    //       [
    //         OWNERSHIP_ADDRESS["sepolia"], // @todo update with correct network at a later stage
    //       ],
    //       {
    //         from: issuer,
    //       },
    //     );
    //   await divaVoucherFactory.waitForDeployment();

    //   // Deploy DIVA Voucher contract instance via factory
    //   await divaVoucherFactory.createDIVAVoucher(issuer.address);

    //   // Extract the DIVA Voucher contract instance address from the event
    //   // Note that in ethers v6, events are no longer part of the transaction receipt.
    //   // Instead, filters have to be used. For more info, read here:
    //   // https://ethereum.stackexchange.com/questions/152626/ethers-6-transaction-receipt-events-information
    //   const filter = divaVoucherFactory.filters.DIVAVoucherCreated;
    //   const events = await divaVoucherFactory.queryFilter(filter, -1);
    //   const event = events[0];
    //   const args = event.args;
    //   const divaVoucherInstanceAddress = args.clone;

    //   // Connect to DIVA Voucher contract instance
    //   const divaVoucher: DIVAVoucher = await hardhatEthers.getContractAt(
    //     "DIVAVoucher",
    //     divaVoucherInstanceAddress,
    //   );

    //   // Retrieve the chainId (relevant for EIP712 related functionality)
    //   const network = await hardhatEthers.provider.getNetwork();
    //   const chainId = Number(network.chainId);

    //   // Define DIVA Domain struct
    //   const divaVoucherDomain: DivaVoucherDomain = {
    //     name: "DIVAVoucher",
    //     version: "1",
    //     chainId,
    //     verifyingContract: divaVoucher.target.toString(),
    //   };

    //   // Fixtures can return anything you consider useful for your tests
    //   return {
    //     divaVoucher,
    //     voucherToken,
    //     issuer,
    //     acc2,
    //     acc3,
    //     chainId,
    //     voucherTokenDecimals,
    //     divaVoucherDomain,
    //   };
    // }
  });
});
