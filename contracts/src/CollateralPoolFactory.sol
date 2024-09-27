// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {ICollateralPoolFactory} from "./interfaces/ICollateralPoolFactory.sol";
import {CollateralPool} from "./CollateralPool.sol";

contract CollateralPoolFactory is ICollateralPoolFactory {
    address[] public collateralPools;

    constructor() {}

    // Function to create a new collateral pool
    // `msg.sender` is set as the manager of the collateral pool
    // Each collateral pool can only be used by one permissioned contract (simple initial version).
    // permissionedContract: DIVAX, which is granted the permission to access the collateral pools
    function createCollateralPool(address _collateralToken, address _permissionedContract) public returns (address) {
        address newCollateralPool = address(
            new CollateralPool(
                msg.sender,
                _collateralToken,
                _permissionedContract // contract eligible to call the `claimPayout` function in `CollateralPool.sol`
            )
        );
        collateralPools.push(newCollateralPool);
        
        emit CollateralPoolCreated(
            newCollateralPool,
            _collateralToken,
            _permissionedContract
        );
        
        return newCollateralPool;
    }

    // @todo Fix re-org vulnerability

    // Get the list of deployed collateral pools
    function getCollateralPools() public view returns (address[] memory) {
        return collateralPools;
    }
}
