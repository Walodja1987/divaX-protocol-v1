// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

import {DIVAX} from '../DIVAX.sol';
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MOVE is DIVAX, ReentrancyGuard {

    struct PayoffParams {
        uint256 strike;
        uint256 slope;
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

    function calculatePayout()

}