// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

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

    struct CreateProductParams {
        string referenceAsset;
        uint256 strike; // could be 2 strikes with flat area
        uint256 slope;
        address collateralPool;
        uint96 expiryTime;
        address dataProvider;
        address permissionedERC721Token;
    }

    struct Product {
        CreateProductParams createProductParams;
        address productToken;
    }

    mapping(bytes32 => Product) public productIdToProduct;

    constructor() {
        
    }

    function createProduct(
        CreateProductParams memory _createProductParams
    ) public returns (bytes32) {
        CollateralPool _collateralPoolInstance = CollateralPool(_createProductParams.collateralPool);
        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());

        bytes32 _productId = _getProductId();

        // Deploy new product token contract

        address productToken = address(0); // @todo replace

        // @todo check whether we can also pass _createProductParams directly like:
        // productIdToProduct[_productId] = _createProductParams
        productIdToProduct[_productId] = Product({
            createProductParams: CreateProductParams({
                referenceAsset: _createProductParams.referenceAsset,
            strike: _createProductParams.strike, // could be 2 strikes with flat area
            slope: _createProductParams.slope,
            collateralPool: _createProductParams.collateralPool,
            expiryTime: _createProductParams.expiryTime,
            dataProvider: _createProductParams.dataProvider,
            permissionedERC721Token: _createProductParams.permissionedERC721Token
            }),
            productToken: productToken
        });

        return _productId;
    }

    function mintProductTokens(bytes32 _productId, uint256 _amount) public {
        Product memory _product = productIdToProduct[_productId];
        CollateralPool _collateralPoolInstance = CollateralPool(_product.createProductParams.collateralPool);

        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());
        


    }

    function _getProductId() private view returns (bytes32 productId) {
        productId = bytes32(0); // @todo adjust
        return productId;
    }
}
