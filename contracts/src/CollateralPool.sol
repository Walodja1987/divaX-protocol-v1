// SPDX-License-Identifier: Unlicense
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

contract CollateralPool {
    address private _collateralPool;

    constructor(
        address manager_,
        address collateralToken_,
        uint256 initialFundingAmount_
    ) {
        _manager = manager_;
        _collateralToken = collateralToken_;

        if (initialFundingAmount_ != 0) {
            if (collateralToken_ == address(0)) {
                // Native token
                
            }
        }
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory newGreeting) public {
        greeting = newGreeting;
    }
}
