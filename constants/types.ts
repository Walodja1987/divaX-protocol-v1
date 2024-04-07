import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { DIVAX, MockERC20 } from "../typechain-types";

export type SetupOutput = {
  divaX: DIVAX;
  collateralToken: MockERC20;
  issuer: SignerWithAddress;
  acc2: SignerWithAddress;
  acc3: SignerWithAddress;
  chainId: number;
  collateralTokenDecimals: number;
};
