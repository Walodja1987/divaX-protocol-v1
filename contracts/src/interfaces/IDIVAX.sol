// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

interface IDIVAX {

    // Thrown in `addCollateral` if `msg.sender` is not designated collateral pool manager.
    error MsgSenderNotManager(address msgSender, address manager);

    // Thrown in `_defineProductTermsGeneral` function if the collateral token has more than 18 decimals.
    error CollateralDecimalsExceed18();

    // Thrown in `setFinalReferenceValue` function if the provided product Id does not exist.
    error NonExistentProduct();

    // Thrown in `setFinalReferenceValue` function if `mgs.sender` is not data provider.
    error NotDataProvider();

    // Thrown in `redeemProductToken` function if the final value was not yet confirmed by the data provider.
    error FinalReferenceValueNotConfirmed();

    // Settlement status.
    enum Status {
        Open,
        Confirmed
    }

}

    