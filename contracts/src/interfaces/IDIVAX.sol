// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

interface IDIVAX {

    // Thrown in `addCollateral` if `msg.sender` is not designated collateral pool manager 
    error MsgSenderNotManager(address msgSender, address manager);

    // Settlement status
    enum Status {
        Open,
        Confirmed
    }

}

    