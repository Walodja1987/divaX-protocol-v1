// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

interface ICollateralPool {
    // Thrown in `addCollateral` if `msg.sender` is not designated collateral pool manager
    error MsgSenderNotManager(address msgSender, address manager);

    // Thrown in `claimPayout` if `msg.sender` is not
    error MsgSenderNotPermissionedContract(address msgSender, address permissionedContract);
}
