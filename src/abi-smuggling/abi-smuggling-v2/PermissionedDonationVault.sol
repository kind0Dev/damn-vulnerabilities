// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title PermissionedDonationVault
 * @notice A vault that manages donations with role-based permissions
 * @dev Contains a vulnerability related to ABI smuggling
 */
contract PermissionedDonationVault is ReentrancyGuard {
    using Address for address;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DONOR_ROLE = keccak256("DONOR_ROLE");

    mapping(address => mapping(bytes32 => bool)) public hasRole;
    mapping(bytes4 => bool) public isAllowedFunction;
    
    uint256 public constant MAX_DONATION = 100 ether;
    uint256 public immutable COOLDOWN_PERIOD;
    uint256 private lastActionTimestamp;

    event DonationReceived(address donor, uint256 amount);
    event FundsDistributed(address beneficiary, uint256 amount);

    error Unauthorized();
    error CooldownNotMet();
    error InvalidAmount();
    error InvalidTarget();

    constructor(uint256 cooldownPeriod) {
        COOLDOWN_PERIOD = cooldownPeriod;
        lastActionTimestamp = block.timestamp;
        
        // Set up allowed functions
        isAllowedFunction[0xe69d849d] = true;
        isAllowedFunction[0xd94f44f1] = true;

        hasRole[msg.sender][ADMIN_ROLE] = true;
    }

    /**
     * @notice Executes a function call if the caller has appropriate permissions
     * @param target The contract to call
     * @param actionData The encoded function call
     */
    function executeAction(address target, bytes calldata actionData) external nonReentrant returns (bytes memory) {
        // Read the 4-bytes selector at the beginning of actionData
        bytes4 selector;
        uint256 calldataOffset = 100; // offset where actionData begins
        assembly {
            selector := calldataload(calldataOffset)
        }

        // Check if caller has appropriate role for this function
        if (selector == this.distributeFunds.selector && !hasRole[msg.sender][ADMIN_ROLE]) {
            revert Unauthorized();
        }
        if (selector == this.donate.selector && !hasRole[msg.sender][DONOR_ROLE]) {
            revert Unauthorized();
        }

        if (!isAllowedFunction[selector]) {
            revert Unauthorized();
        }

        if (target != address(this)) {
            revert InvalidTarget();
        }

        return target.functionCall(actionData);
    }

    /**
     * @notice Allows donors to contribute funds
     * @param token The token to donate
     * @param amount The amount to donate
     */
    function donate(address token, uint256 amount) external {
        if (msg.sender != address(this)) revert Unauthorized();
        if (amount > MAX_DONATION) revert InvalidAmount();
        
        SafeTransferLib.safeTransferFrom(token, tx.origin, address(this), amount);
        emit DonationReceived(tx.origin, amount);
    }

    /**
     * @notice Allows admins to distribute funds to beneficiaries
     * @param token The token to distribute
     * @param beneficiary The recipient of the funds
     */
    function distributeFunds(address token, address beneficiary) external {
        if (msg.sender != address(this)) revert Unauthorized();
        if (block.timestamp <= lastActionTimestamp + COOLDOWN_PERIOD) {
            revert CooldownNotMet();
        }

        lastActionTimestamp = block.timestamp;
        uint256 balance = IERC20(token).balanceOf(address(this));
        SafeTransferLib.safeTransfer(token, beneficiary, balance);
        emit FundsDistributed(beneficiary, balance);
    }

    /**
     * @notice Grants a role to an account
     * @param account The account to receive the role
     * @param role The role to grant
     */
    function grantRole(address account, bytes32 role) external {
        if (!hasRole[msg.sender][ADMIN_ROLE]) revert Unauthorized();
        hasRole[account][role] = true;
    }

    function getLastActionTimestamp() external view returns (uint256) {
        return lastActionTimestamp;
    }
}