//SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 number = 1;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // number = 2;
        //  us -> FundMeTest -> FundMe
        // fundMe = new FundMe(0x694AssA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        // assertEq(number, 2);
    }

    function testOwnerIsMsgSender() public view {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What we can do to work with addresses outside our systen?
    // 1. Unit
    //     - Testing a specific part of our code
    // 2. Integration
    //     - Testing how our code works with other parts of code
    // 3. Forked
    //     - Testing our code on a simulated real environment
    // 4. Staging
    //     - Testing our code in a real environment that is not prod
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // hey, the next line, should revert!
        // asssert(This tx falls/reverts)
        // uint256 cat = 1;
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //ensure onlyowner can call the withdraw
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
        // assertEq(fundMe.getAddressToAmountFunded(address(this)), 0);
        // assertEq(fundMe.getFunder(0), address(0));
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //balance of the person deploying the contract
        uint256 StartingFundMeBalance = address(fundMe).balance; // balance of the contract after funded

        // Act: withdraw from the contract
        uint256 gasStart = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // c: 200
        fundMe.withdraw(); //should have spent gas?

        uint256 gasEnd = gasleft(); //800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            StartingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            startingFunderIndex;
            startingFunderIndex < numberOfFunders;
            startingFunderIndex++
        ) {
            hoax(address(startingFunderIndex), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            startingFunderIndex;
            startingFunderIndex < numberOfFunders;
            startingFunderIndex++
        ) {
            hoax(address(startingFunderIndex), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

// vm.prank new address
// vm.deal new address
//address(0)
// fund the fundMe
