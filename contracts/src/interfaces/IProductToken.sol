// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @notice Product token contract
 * @dev The `ProductToken` contract inherits from ERC20 contract and stores
 * the Id of the pool that the product token is linked to. It implements a
 * `mint` and a `burn` function which can only be called by the `ProductToken`
 * contract owner.
 *
 * Two `ProductToken` contracts are deployed during pool creation process
 * (`createContingentPool`) with Diamond contract being set as the owner.
 * The `mint` function is used during pool creation (`createContingentPool`)
 * and addition of liquidity (`addLiquidity`). Product tokens are burnt
 * during token redemption (`redeemProductToken`) and removal of liquidity
 * (`removeLiquidity`). The address of the product tokens is stored in the
 * pool parameters within Diamond contract and used to verify the tokens that
 * a user sends back to withdraw collateral.
 *
 * Product tokens have the same number of decimals as the underlying
 * collateral token.
 */
interface IProductToken {
    /**
     * @notice Function to initialize the product token instance
     */
    function initialize(
        string memory symbol_, // name is set equal to symbol
        bytes32 poolId_,
        uint8 decimals_,
        address owner_
    ) external;

    /**
     * @notice Function to mint ERC20 product tokens.
     * @dev Called during  `createContingentPool` and `addLiquidity`.
     * Can only be called by the owner of the product token which
     * is the Diamond contract in the context of DIVA.
     * @param _recipient The account receiving the product tokens.
     * @param _amount The number of product tokens to mint.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @notice Function to burn product tokens.
     * @dev Called within `redeemProductToken` and `removeLiquidity`.
     * Can only be called by the owner of the product token which
     * is the Diamond contract in the context of DIVA.
     * @param _redeemer Address redeeming products tokens in return for
     * collateral.
     * @param _amount The number of product tokens to burn.
     */
    function burn(address _redeemer, uint256 _amount) external;

    /**
     * @notice Returns the Id of the contingent pool that the product token is
     * linked to in the context of DIVA.
     * @return The poolId.
     */
    function poolId() external view returns (bytes32);

    /**
     * @notice Returns the owner of the product token (Diamond contract in the
     * context of DIVA).
     * @return The address of the product token owner.
     */
    function owner() external view returns (address);
}
