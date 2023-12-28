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
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IDIVAX} from './interfaces/IDIVAX.sol';
import {IProductTokenFactory} from './interfaces/IProductTokenFactory.sol';
import {IProductToken} from './interfaces/IProductToken.sol';

contract DIVAX is IDIVAX, ReentrancyGuard {

    uint256 private _nonce;
    address private _productTokenFactory;

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

    constructor(address productTokenFactory_) {
        _productTokenFactory = productTokenFactory_;
    }

    function createProduct(
        CreateProductParams memory _createProductParams
    ) public returns (bytes32) {
        CollateralPool _collateralPoolInstance = CollateralPool(_createProductParams.collateralPool);
        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());

        ++_nonce;
        
        bytes32 _productId = _getProductId(); // @todo implement function


        // Deploy new product token contract
        uint8 _collateralTokenDecimals = IERC20Metadata(_collateralPoolInstance.getCollateralToken()).decimals();
        address _productToken = IProductTokenFactory(_productTokenFactory)
            .createProductToken(
                string(abi.encodePacked("X", Strings.toString(_nonce))), // name is equal to symbol
                _productId,
                _collateralTokenDecimals,
                address(this),
                _createProductParams.permissionedERC721Token
            );

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
            productToken: _productToken
        });

        return _productId;
    }

    function mintProductTokens(bytes32 _productId, uint256 _amount) public {
        Product memory _product = productIdToProduct[_productId];
        CollateralPool _collateralPoolInstance = CollateralPool(_product.createProductParams.collateralPool);

        address _manager = _collateralPoolInstance.getManager();

        if (msg.sender != _manager) revert MsgSenderNotManager(msg.sender, _manager);
        
        IProductToken(_product.productToken).mint(_manager, _amount);

        // @todo emit event
    }

    function _getProductId() private view returns (bytes32 productId) {
        productId = bytes32(0); // @todo adjust
        return productId;
    }

    // @todo interesting idea: bankruptcy process on-chain
}
