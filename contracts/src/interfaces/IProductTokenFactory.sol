// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

interface IProductTokenFactory {
    /**
     * @notice Creates a clone of the permissionless product token contract.
     * @param _symbol Symbol string of the product token. Name is set equal to symbol.
     * @param _poolId The Id of the contingent pool that the product token belongs to.
     * @param _decimals Decimals of product token (same as collateral token).
     * @param _owner Owner of the product token. Should always be DIVA Protocol address.
     * @param _permissionedERC721Token Address of permissioned ERC721 token.
     * @return clone Returns the address of the clone contract.
     */
    function createProductToken(
        string memory _symbol,
        bytes32 _poolId,
        uint8 _decimals,
        address _owner,
        address _permissionedERC721Token
    ) external returns (address clone);

    /**
     * @notice Address where the product token implementation contract is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
     */
    function productTokenImplementation() external view returns (address);

    /**
     * @notice Address where the permissioned product token implementation contract
     * is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
     */
    function permissionedProductTokenImplementation() external view returns (address);
}
