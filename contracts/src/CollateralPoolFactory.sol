// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {CollateralPool} from "./CollateralPool.sol";

contract CollateralPoolFactory {
    address[] public collateralPools;

    constructor() {
    }

    // Function to create a new collateral pool
    // `msg.sender` is set as the manager of the collateral pool
    // Each collateral pool can only be used by one permissioned contract (simple initial version).
    function createCollateralPool(address _collateralToken, address _permissionedContract) public {
        address newCollateralPool = address(
            new CollateralPool(
                msg.sender,
                _collateralToken,
                _permissionedContract // contract eligible to call the `claimPayout` function in `CollateralPool.sol`
            )
        );
        collateralPools.push(newCollateralPool);
    }

    // Get the list of deployed collateral pools
    function getCollateralPools() public view returns (address[] memory) {
        return collateralPools;
    }
}
