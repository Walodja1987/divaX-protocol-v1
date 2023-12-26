// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

interface ICollateralPool {

    // Thrown in `constructor` if the transfer of the gas token failed.
    error FailedGasTokenTransfer();
}

    