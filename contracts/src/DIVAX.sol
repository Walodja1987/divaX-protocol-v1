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

// @todo Read about inheritance linearlization as I had an issue with that at some point: https://docs.soliditylang.org/en/develop/contracts.html#multiple-inheritance-and-linearization

// Only a template
import {CollateralPool} from './CollateralPool.sol'; // Question: Could we also use the interface here?
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IDIVAX} from './interfaces/IDIVAX.sol';
import {IProductTokenFactory} from './interfaces/IProductTokenFactory.sol';
import {IProductToken} from './interfaces/IProductToken.sol';

abstract contract DIVAX is IDIVAX, ReentrancyGuard {

    address private _productTokenFactory;
    uint256 internal _nonce;

    struct ProductTermsGeneralInput {
        string referenceAsset;
        address collateralPool;
        uint96 expiryTime;
        address dataProvider;
        address permissionedERC721Token;
        uint256 denominationInCollateralToken; // in collateral token decimals; performance is calculated relative to strikes
    }

    struct ProductTermsGeneral {
        ProductTermsGeneralInput productTermsGeneralInput;
        address productToken;
        uint256 finalReferenceValue; // 18 decimals
        uint256 payoutPerProductToken; // in collateral token decimals
        Status status;
    }

    mapping(bytes32 => ProductTermsGeneral) public productIdToProductTermsGeneral; // payoff-independent params

    constructor(address productTokenFactory_) {
        _productTokenFactory = productTokenFactory_;
    }

    function _defineProductTermsGeneral(
        ProductTermsGeneralInput calldata _productTermsGeneralInput,
        bytes32 _payoffParamsHash,
        string memory _productName
    ) internal returns (bytes32) {
        CollateralPool _collateralPoolInstance = CollateralPool(_productTermsGeneralInput.collateralPool);
        if (msg.sender != _collateralPoolInstance.getManager())
            revert MsgSenderNotManager(msg.sender, _collateralPoolInstance.getManager());

        bytes32 _productId = _generateProductId(_productTermsGeneralInput, _payoffParamsHash);

        // Deploy new product token contract
        uint8 _collateralTokenDecimals = IERC20Metadata(_collateralPoolInstance.getCollateralToken()).decimals();

        if (_collateralTokenDecimals > 18) revert CollateralDecimalsExceed18(); // @todo add error in interface

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
                permissionedERC721Token: _productTermsGeneralInput.permissionedERC721Token,
                denominationInCollateralToken: _productTermsGeneralInput.denominationInCollateralToken
            }),
            productToken: _productToken,
            finalReferenceValue: 0,
            payoutPerProductToken: 0,
            status: Status.Open
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

    function _generateProductId(
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

    // @todo Consider checking expiry time. Maybe better to implement expiry time check inside the
    // oracle adapter
    function setFinalReferenceValue(
        bytes32 _productId,
        uint256 _finalReferenceValue
    ) public {
        // Check if productId exists
        if (!_productExists(_productId)) revert NonExistentProduct(); // @todo add _productExists function and NonExistentProduct error

        ProductTermsGeneral storage _productTermsGeneral = productIdToProductTermsGeneral[_productId];

        if (msg.sender != _productTermsGeneral.productTermsGeneralInput.dataProvider) revert NotDataProvider(); // @todo NotDataProvider

        _productTermsGeneral.finalReferenceValue = _finalReferenceValue;
        _productTermsGeneral.status = Status.Confirmed; // Confirmed

        _setPayoutPerProductToken(_productId); // Use the one implemented in MOVE contract; @todo alternative approach: define 
        // _setPayoutPerProductToken as internal virtual without any contract code inside this contract and then inside MOVE contract, you 
        // define it again but as with override keyword -> Would make DIVAX and abstract, as _setPayoutPerProductToken function
        // is not implemented herein
    }

    function _setPayoutPerProductToken(bytes32 _productId) internal virtual;

    function _productExists(bytes32 _productId) private view returns (bool) {
        // @todo Some code
    }

    function redeemProductToken(
        bytes32 _productId,
        uint256 _amount
    ) public {
        ProductTermsGeneral memory _product = productIdToProductTermsGeneral[_productId];

        // Burn product tokens. Will revert if `msg.sender` has a balance less than
        // `_amount` (checked inside `burn` function).
        IProductToken(_product.productToken).burn(msg.sender, _amount);

        if (_product.status == Status.Confirmed) {
            // calculate
            CollateralPool _collateralPoolInstance = CollateralPool(_product.productTermsGeneralInput.collateralPool); // Question: Could we also use the interface here?
            _collateralPoolInstance.claimPayout(_amount * _product.payoutPerProductToken, msg.sender); // Question: Any overflow issues?
        } else {
            revert FinalReferenceValueNotConfirmed(); // @todo add error to interface
        }
    }
    // @todo interesting idea: bankruptcy process on-chain

    // @todo Consider adding coupon logic

    // @todo add fee logic

    // @todo Are WorstOf/Basket/Rainbow options possible?
}
