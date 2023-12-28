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
    address private immutable _permissionedContract;

    modifier onlyManager() {
        if (msg.sender != _manager) revert MsgSenderNotManager(msg.sender, _manager);
        _;
    }

    modifier onlyPermissionedContract() {
        if (msg.sender != _permissionedContract) revert MsgSenderNotPermissionedContract(msg.sender, _permissionedContract);
        _;
    }

    constructor(
        address manager_,
        address collateralToken_,
        address permissionedContract_
    ) {
        _manager = manager_; // `msg.sender` in factory contract
        _collateralToken = collateralToken_;
        _permissionedContract = permissionedContract_;
    }

    // @todo handle direct eth transfers (receive/fallback function)

    // @todo add to interface
    // Safer to deposit via addCollateral as it includes a collateral check
    // Anyone could add collateral
    function addCollateral(uint256 _amount) public {
        IERC20 _collateralTokenInstance = IERC20(_collateralToken);
        _collateralTokenInstance.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // @todo add to interface
    function removeCollateral(uint256 _amount) public onlyManager {       
        // ERC20 token; requires prior user approval to transfer the token.
        // Will revert if user has insufficient token balance.
        IERC20 _collateralTokenInstance = IERC20(_collateralToken);
        _collateralTokenInstance.safeTransfer(msg.sender, _amount);
    }

    function claimPayout(uint256 _amount, address _recipient) public onlyPermissionedContract {
        IERC20 _collateralTokenInstance = IERC20(_collateralToken);
        _collateralTokenInstance.safeTransfer(_recipient, _amount);
    }

    function getManager() public view returns (address) {
        return _manager;
    }

    // @todo Add mechanism to check collateral vs. current exposure
}
