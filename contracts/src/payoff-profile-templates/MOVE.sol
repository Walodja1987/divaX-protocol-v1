// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

import {DIVAX} from '../DIVAX.sol';
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MOVE is DIVAX, ReentrancyGuard {

    struct PayoffParams {
        uint256 strike; // 18 decimals (same as finalReferenceValue)
        uint256 slope; // 18 decimals (same as finalReferenceValue)
    }

    mapping(bytes32 => PayoffParams) public productIdToPayoffParams;

    function defineMOVEProductTerms(
        DIVAX.ProductTermsGeneralInput memory _productTermsGeneralInput,
        PayoffParams memory _payoffParams // Move product specific params
    ) public nonReentrant returns (bytes32) {

        bytes32 _payoffParamsHash = _getPayoffParamsHash(_payoffParams);
                
        // @todo Consider calculating productId in two steps, first from product terms general which can be done inside DIVAX
        // and the from payoff specific params
        string _productName = string(abi.encodePacked("MOVE", Strings.toString(DIVAX._nonce)));

        bytes32 _productId = DIVAX._defineProductTermsGeneral(
            _productTermsGeneralInput,
            _payoffParamsHash,
            _productName
        ); // creates the payoff-independent parts of the product
        
        // @todo check whether we can also pass _productTermsGeneralInput directly like:
        // productIdToProduct[_productId] = _productTermsGeneralInput
        // Part that is payoff-dependent
        productIdToPayoffParams[_productId] = PayoffParams({
            strike: _payoffParams.strike, // could be 2 strikes with flat area
            slope: _payoffParams.slope,
        });

        return _productId;
    }

    // payoff-specific
    function _getPayoffParamsHash(PayoffParams calldata _payoffParams) private view returns (bytes32) {        
        // Assembly for more efficient computing:
        // bytes32 _payoffParamsHash = keccak256(
        //     abi.encode(
        //         _payoffParams.strike,
        //         _payoffParams.slope,
        //         msg.sender,
        //     )
        // );
        // @todo optimize using assembly
        bytes32 _payoffParamsHash = keccak256(
            abi.encode(
                _payoffParams.strike,
                _payoffParams.slope,
                msg.sender
            )
        );
        return _payoffParamsHash;
    }

    function _calculatePayoutPerProductToken(
        DIVAX.ProductTermsGeneral memory _productTermsGeneral,
        PayoffParams memory _payoffParams,
        uint256 _referenceValue
    ) private returns (uint256) {
        if (_productTermsGeneral.finalReferenceValue > _payoffParams.strike) {
            _referencePerformance = 
                (_productTermsGeneral.finalReferenceValue - _payoffParams.strike) / _payoffParams.strike;
        } else {
            _referencePerformance = 
                (_payoffParams.strike - _productTermsGeneral.finalReferenceValue) / _payoffParams.strike;
        }


        CollateralPool _collateralPoolInstance = CollateralPool(_productTermsGeneral.collateralPool);
        uint8 _collateralTokenDecimals = IERC20Metadata(_collateralPoolInstance.getCollateralToken()).decimals();
        uint256 _SCALINGFACTOR;
        unchecked {
            // Cannot over-/underflow as collateral token decimals are restricted to
            // a minimum of 0 and a maximum of 18.
            // @todo does decimals = 0 create some problems in payoff calcs?
            _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        }
        uint256 _UNIT = uint256(10**(18)); // @todo consider using `uint256 _UNIT = SafeDecimalMath.UNIT;`
        return _referencePerformance * _payoffParams.slope * denominationInCollateralToken * _SCALINGFACTOR / (_UNIT * _UNIT);
    }

    function calculatePayoutPerProductToken(bytes32 _productId, uint256 _referenceValue) public returns (uint256) {
        DIVAX.ProductTermsGeneral memory _productTermsGeneral = productIdToProductTermsGeneral[_productId];
        PayoffParams memory _payoffParams = productIdToPayoffParams[_productId];
        return _calculatePayoutPerProductToken(_productTermsGeneral, _payoffParams, _referenceValue);        
    }

    // Required for every payoff contract (@todo move into interface)
    function _setPayoutPerProductToken(bytes32 _productId) internal {
        DIVAX.ProductTermsGeneral storage _productTermsGeneral = productIdToProductTermsGeneral[_productId];
        PayoffParams memory _payoffParams = productIdToPayoffParams[_productId];

        _productTermsGeneral.payoutPerProductToken = 
            _calculatePayoutPerProductToken(
                _productTermsGeneral,
                _payoffParams,
                _productTermsGeneral.finalReferenceValue,                
            );
    }
}