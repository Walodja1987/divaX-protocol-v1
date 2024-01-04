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

// Only a template
import {CollateralPool} from './CollateralPool.sol';
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IDIVAX} from './interfaces/IDIVAX.sol';
import {IProductTokenFactory} from './interfaces/IProductTokenFactory.sol';
import {IProductToken} from './interfaces/IProductToken.sol';

contract DIVAX is IDIVAX, ReentrancyGuard {

    address private _productTokenFactory;
    uint256 internal _nonce;

    struct ProductTermsGeneralInput {
        string referenceAsset;
        address collateralPool;
        uint96 expiryTime;
        address dataProvider;
        address permissionedERC721Token;
    }

    struct ProductTermsGeneral {
        ProductTermsGeneralInput productTermsGeneralInput;
        address productToken;
    }

    mapping(bytes32 => ProductTermsGeneral) public productIdToProductTermsGeneral; // payoff-independent params

    constructor(address productTokenFactory_) {
        _productTokenFactory = productTokenFactory_;
    }

    function _defineProductTermsGeneral(
        ProductTermsGeneralInput memory _productTermsGeneralInput,
        bytes32 _payoffParamsHash,
        string memory _productName
    ) internal returns (bytes32) {
        CollateralPool _collateralPoolInstance = CollateralPool(_productTermsGeneralInput.collateralPool);
        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());

        bytes32 _productId = _getProductId(_productTermsGeneralInput, _payoffParamsHash); // @todo implement function (derived from PayoffParams und DIVAXParams inherited from DIVAX) nonce + hash of all parameters in PayoffParams and DIVAXParams

        // Deploy new product token contract
        uint8 _collateralTokenDecimals = IERC20Metadata(_collateralPoolInstance.getCollateralToken()).decimals();
        address _productToken = IProductTokenFactory(_productTokenFactory)
            .createProductToken(
                _productName,
                _productId,
                _collateralTokenDecimals,
                address(this),
                _productTermsGeneralInput.permissionedERC721Token
            );

        // // @todo check whether we can also pass _productTermsGeneralInput directly like:
        // // productIdToProductTermsGeneral[_productId] = _productTermsGeneralInput
        productIdToProductTermsGeneral[_productId] = ProductTermsGeneral({
            productTermsGeneralInput: ProductTermsGeneralInput({
                referenceAsset: _productTermsGeneralInput.referenceAsset,
                collateralPool: _productTermsGeneralInput.collateralPool,
                expiryTime: _productTermsGeneralInput.expiryTime,
                dataProvider: _productTermsGeneralInput.dataProvider,
                permissionedERC721Token: _productTermsGeneralInput.permissionedERC721Token
            }),
            productToken: _productToken
        });

        return _productId;
    }

    function mintProductTokens(bytes32 _productId, uint256 _amount) public nonReentrant {
        ProductTermsGeneral memory _product = productIdToProductTermsGeneral[_productId];
        CollateralPool _collateralPoolInstance = CollateralPool(_product.productTermsGeneralInput.collateralPool);

        address _manager = _collateralPoolInstance.getManager();

        if (msg.sender != _manager) revert MsgSenderNotManager(msg.sender, _manager);
        
        IProductToken(_product.productToken).mint(_manager, _amount);

        // @todo emit event
    }

    function _getProductId(
        ProductTermsGeneralInput calldata _productTermsGeneralInput,
        bytes32 _payoffParamsHash
    ) internal returns (bytes32) {
        // Assembly for more efficient computing:
        // bytes32 _productId = keccak256(
        //     abi.encode(
        //         keccak256(bytes(_productTermsGeneralInput.referenceAsset)),
        //         _productTermsGeneralInput.collateralPool,
        //         _productTermsGeneralInput.expiryTime,
        //         _productTermsGeneralInput.dataProvider,
        //         _productTermsGeneralInput.permissionedERC721Token,
        //         _payoffParamsHash,
        //         msg.sender,
        //         _nonce
        //     )
        // );
        
        ++_nonce; // productID calcs need to take nonce as input to make it unique
        // @todo optimize using assembly
        bytes32 _productId = keccak256(
            abi.encode(
                keccak256(bytes(_productTermsGeneralInput.referenceAsset)),
                _productTermsGeneralInput.collateralPool,
                _productTermsGeneralInput.expiryTime,
                _productTermsGeneralInput.dataProvider,
                _productTermsGeneralInput.permissionedERC721Token,
                _payoffParamsHash,
                msg.sender,
                _nonce
            )
        );

        return _productId;
    }


    function setFinalReferenceValue(
        bytes32 _productId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) public {

    }

    function redeemPositionToken(
        address _positionToken,
        uint256 _amount
    ) public {
        // calculate
        CollateralPool.claimPayout();
    }





    // @todo interesting idea: bankruptcy process on-chain
}
