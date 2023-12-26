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


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ICollateralPool} from './interfaces/ICollateralPool.sol';

contract CollateralPool is ICollateralPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable _manager;
    address private immutable _collateralToken;

    constructor(
        address manager_,
        address collateralToken_,
        uint256 initialFundingAmount_
    ) {
        _manager = manager_;
        _collateralToken = collateralToken_;

        if (initialFundingAmount_ != 0) {
            _addLiquidity(initialFundingAmount_, collateralToken_);
        }
    }

    function _addLiquidity(uint256 _amount, address collateralToken_) private {
        if (collateralToken_ == address(0)) {
            // Native gas token (e.g., ETH)
            (bool success, ) = msg.sender.call{value: _amount}("");
            if (!success) revert FailedGasTokenTransfer();
        } else {
            // ERC20 token; requires prior user approval to transfer the token
            IERC20 _collateralTokenInstance = IERC20(collateralToken_);
            _collateralTokenInstance.safeTransfer(msg.sender, _amount);
        }
    }
}
