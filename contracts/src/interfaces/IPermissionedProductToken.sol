// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Permissioned version of the product token contract
 */
interface IPermissionedProductToken is IERC20Upgradeable {
    /**
     * @notice Function to initialize the product token instance
     */
    function initialize(
        string memory symbol_, // name is set equal to symbol
        bytes32 poolId_,
        uint8 decimals_,
        address owner_,
        address permissionedERC721Token_
    ) external;

    /**
     * @notice Function to mint ERC20 product tokens. Called during
     * `createContingentPool` and `addLiquidity`. Can only be called by the
     * owner of the product token which is the Diamond contract in the
     * context of DIVA.
     * @param _recipient The account receiving the product tokens.
     * @param _amount The number of product tokens to mint.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @notice Function to burn product tokens. Called within `redeemProductToken`
     * and `removeLiquidity`. Can only be called by the owner of the product
     * token which is the Diamond contract in the context of DIVA.
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

    /**
     * @notice Return permissioned ERC721 token address.
     * @return The address of the permissioned ERC721 token.
     */
    function permissionedERC721Token() external view returns (address);
}
