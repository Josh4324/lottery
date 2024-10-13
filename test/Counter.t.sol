// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SmartLottery} from "../src/Lottery.sol";

contract CounterTest is Test {
    SmartLottery public lottery;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        vm.startPrank(owner);
        lottery = new SmartLottery(1);
        vm.stopPrank();
    }

    function test_Lot() public {
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        lottery.createLottery(1 ether, block.timestamp, block.timestamp + 10 days);
        lottery.createLottery(1 ether, block.timestamp, block.timestamp + 10 days);
        lottery.createLottery(1 ether, block.timestamp, block.timestamp + 10 days);

        vm.warp(block.timestamp + 1 days);

        lottery.enterLottery{value: 1 ether}(1);

        vm.warp(block.timestamp + 6 days);

        lottery.enterLottery{value: 1 ether}(1);

        lottery.enterLottery{value: 1 ether}(1);

        lottery.DrawLotteryWinner(0);

        vm.stopPrank();
    }
}
