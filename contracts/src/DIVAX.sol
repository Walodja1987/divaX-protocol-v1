// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

// Collateral management:
// createCollateralPool (on-chain)
// add/removeCollateral (on-chain)

// Product creation & management:
// defineProductTerms (on-chain): define terms; what is underlying, what is collateral pool address, payout profile reference (extendable approach to include more products in the future)
// generateClaims (equivalent to addLiquidity in DIVA Protocol): generates LONG tokens and sends them to MM which he then can sell via 0x/EIP712; has more control that way.
// fillofferGenerateClaim (EIP712 based version)
// burnClaims (keine wichtige Funktion; nur MM kann LONG tokens, die er selber hält, burnen); kann LONG tokens dann aus Versehen nicht verkaufen; wallet sieht sauberer aus

// Settlement:
// reportPrice / oracle
// Handle case where not enough collateral to redeem

import {CollateralPool} from './CollateralPool.sol';
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IDIVAX} from './interfaces/IDIVAX.sol';

contract DIVAX is IDIVAX, ReentrancyGuard {
    
    struct ProductParams {
        string referenceAsset;
        uint256 strike; // could be 2 strikes with flat area
        uint256 slope;
        address collateralPool;
        uint96 expiryTime;
        address dataProvider;
        address permissionedERC721Token;
    }

    mapping(bytes32 => ProductParams) public productIdToProductParams;

    constructor() {
        
    }

    function createProduct(
        ProductParams memory _productParams
    ) public returns (bytes32) {
        CollateralPool _collateralPoolInstance = CollateralPool(_productParams.collateralPool);
        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());

        bytes32 _productId = _getProductId();

        // @todo check whether we can also pass _productParams directly like:
        // productIdToProductParams[_productId] = _productParams
        productIdToProductParams[_productId] = ProductParams({
            referenceAsset: _productParams.referenceAsset,
            strike: _productParams.strike, // could be 2 strikes with flat area
            slope: _productParams.slope,
            collateralPool: _productParams.collateralPool,
            expiryTime: _productParams.expiryTime,
            dataProvider: _productParams.dataProvider,
            permissionedERC721Token: _productParams.permissionedERC721Token
        });

        return _productId;
    }

    function _getProductId() private view returns (bytes32 productId) {
        productId = bytes32(0); // @todo adjust
        return productId;
    }
}
