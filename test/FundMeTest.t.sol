// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
//console.log("USER:",USER);


contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); //Creat fake sender address to avoid confusion.
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //Give fake money to fake user!
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }

    //Some codes are from Foundry Book, Cheatcodes Reference, Environment.

    function testFundFailsWithoutEnoughETH() public{ //forge test --match-test yourFunctionName
        vm.expectRevert(); //The next line should revert!
        fundMe.fund(); //send 0 value
    }

    modifier funded() {
        vm.prank(USER); //The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;        
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.addressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }


    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //uint256 gasStart = gasleft(); //Simulate Gas
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10; //For generating addresses with number should use uint160
        uint160 startingFunderIndex = 1; //Do not use index 0 for testing
        for(uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    } 
}

