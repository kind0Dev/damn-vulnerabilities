// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";
import {BackdoorAttack} from "../../src/attacker-contracts/BackdoorAttack.sol";


contract BackdoorChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    address[] users = [makeAddr("alice"), makeAddr("bob"), makeAddr("charlie"), makeAddr("david")];

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;

    DamnValuableToken token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

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
        // Deploy Safe copy and factory
        singletonCopy = new Safe();
        walletFactory = new SafeProxyFactory();

        // Deploy reward token
        token = new DamnValuableToken();

        // Deploy the registry
        walletRegistry = new WalletRegistry(address(singletonCopy), address(walletFactory), address(token), users);

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(walletRegistry.owner(), deployer);
        assertEq(token.balanceOf(address(walletRegistry)), AMOUNT_TOKENS_DISTRIBUTED);
        for (uint256 i = 0; i < users.length; i++) {
            // Users are registered as beneficiaries
            assertTrue(walletRegistry.beneficiaries(users[i]));

            // User cannot add beneficiaries
            vm.expectRevert(0x82b42900); // `Unauthorized()`
            vm.prank(users[i]);
            walletRegistry.addBeneficiary(users[i]);
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_backdoor() public checkSolvedByPlayer {

             * Most of the logic is placed in the Smart Contract to allow this to happen
     * in one transaction. But essentially it goes:
     * 
     * 1. Deploy malicious contract
     * 2. Generate the ABI to call the setupToken() function in the malicious contract
     * 3. exploit(): Call exploit with the above ABI and the list of users
     * 4. exploit(): Generate the ABI to setup the new Gnosis wallet with the ABI from step 2
     *                  such that the callback address and function is the wallet registry
     * 5. exploit(): Call the ProxyFactory contract with the ABI from step 4 and a few other bobs
     *              with a callback to the WalletRegistry proxyCreated() function.
     * 6. createProxyWithCallback(): Deploys the new Proxy and calls setup() on the proxy
     * 7. setup(): New proxy is setup and sets up the module calling back to the malicous contract
     *              however this time is a delegate call meaning it is executed in the context
     *              of the newly create proxy contract.
     * 8. setupToken(): [proxy context] Approve 10 ether to be spent by the malicious contract
     *                  of the proxies token funds
     * 9. proxyCreated(): Callback executed on the wallet registry and passes checks and transfers
     *                      10 ether to the newly created wallet
     * 10. exploit(): Transfer the 10 ether from the Gnosis wallet to the attacker address
     * 11. Repeat for each beneficiary from within the contract and hence 1 transaction.
     * Attact contract can be found in the attack-contracts/BackdoorAttack.sol
     * After which you just deploy the BackdoorAttack and transfer all the token to the recovery address

    BackdoorAttack bkAttack = new BackdoorAttack(
        player,
        address(walletFactory),
        address(singletonCopy),
        address(walletRegistry),
        address(token),
        users
    );

    console.log(token.balanceOf(player));

    token.transfer(recovery, AMOUNT_TOKENS_DISTRIBUTED);

    console.log(token.balanceOf(player));
        
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        for (uint256 i = 0; i < users.length; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            assertTrue(wallet != address(0), "User didn't register a wallet");

            // User is no longer registered as a beneficiary
            assertFalse(walletRegistry.beneficiaries(users[i]));
        }

        // Recovery account must own all tokens
        assertEq(token.balanceOf(recovery), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
