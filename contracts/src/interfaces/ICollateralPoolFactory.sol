// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

interface ICollateralPoolFactory {
    
    event CollateralPoolCreated(
        address indexed collateralPool,
        address indexed collateralToken,
        address indexed permissionedContract
    );
}
