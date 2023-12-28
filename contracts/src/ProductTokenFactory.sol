// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23; // @todo remove ^

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IProductTokenFactory} from "./interfaces/IProductTokenFactory.sol";
import {ProductToken} from "./ProductToken.sol";
import {PermissionedProductToken} from "./PermissionedProductToken.sol";
import {IProductToken} from "./interfaces/IProductToken.sol";
import {IPermissionedProductToken} from "./interfaces/IPermissionedProductToken.sol";


/**
 * @dev Factory contract to create product token clones
 */
contract ProductTokenFactory is IProductTokenFactory {
    address private immutable _PRODUCT_TOKEN_IMPLEMENTATION;
    address private immutable _PERMISSIONED_PRODUCT_TOKEN_IMPLEMENTATION;

    constructor() payable {
        // Using payable to reduce deployment costs

        _PRODUCT_TOKEN_IMPLEMENTATION = address(new ProductToken());
        _PERMISSIONED_PRODUCT_TOKEN_IMPLEMENTATION = address(new PermissionedProductToken());
    }

    function createProductToken(
        string memory symbol_,
        bytes32 poolId_,
        uint8 decimals_,
        address owner_,
        address permissionedERC721Token_
    ) external override returns (address) {
        
        address clone;

        // Initialize product token contract as implementation contract
        // doesn't have a constructor
        if (permissionedERC721Token_ == address(0)) {
            clone = Clones.clone(_PRODUCT_TOKEN_IMPLEMENTATION);
            IProductToken(clone).initialize(
                symbol_,
                poolId_,
                decimals_,
                owner_
            );
        } else {
            clone = Clones.clone(_PERMISSIONED_PRODUCT_TOKEN_IMPLEMENTATION);
            IPermissionedProductToken(clone).initialize(
                symbol_,
                poolId_,
                decimals_,
                owner_,
                permissionedERC721Token_
            );
        }
        
        return clone;
    }

    function productTokenImplementation() external view override returns (address) {
        return _PRODUCT_TOKEN_IMPLEMENTATION;
    }

    function permissionedProductTokenImplementation() external view override returns (address) {
        return _PERMISSIONED_PRODUCT_TOKEN_IMPLEMENTATION;
    }
}