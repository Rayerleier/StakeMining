pragma solidity ^0.8.0;

import {RNTToken} from "../src/RNTToken.sol";
import {ESRNTToken} from "../src/ESRNTToken.sol";
import {RNTStake} from "../src/RNTStake.sol";
import {Test, console} from "forge-std/Test.sol";

contract RNTStakeTest is Test {
    address owner = makeAddr("owner");
    address stakeHolder1 = makeAddr("stakeHolder1");
    // address stakeHolder2 = makeAddr("stakeHolder2");
    RNTStake rntstake;
    RNTToken rnttoken;
    ESRNTToken esrntotken;

    function setUp() public {
        vm.startPrank(owner);
        rnttoken = new RNTToken();
        esrntotken = new ESRNTToken();
        rntstake = new RNTStake(address(rnttoken), address(esrntotken));
        rnttoken.mint(stakeHolder1, 100_000_000 * 1e18);
        // rnttoken.mint(stakeHolder2, 100_000_000 * 1e18);
    }

    function test_stake() public {
        uint256 price1 = 80_000_000 * 1e18;
        uint256 price2 = 20_000_000 * 1e18;
        _stake(stakeHolder1, price1);
        assertEq(rntstake.amountOfStake(stakeHolder1), price1);
        assertEq(rnttoken.balanceOf(stakeHolder1), 100_000_000 * 1e18 - price1);
        vm.warp(block.timestamp + 2 days);
        _stake(stakeHolder1, price2);
        assertEq(rntstake.amountOfStake(stakeHolder1), price1 + price2);
        assertEq(
            rnttoken.balanceOf(stakeHolder1),
            100_000_000 * 1e18 - price1 - price2
        );

        assertEq(rntstake.mintableTokenOfStake(stakeHolder1), price1 * 2);
    }

    function _stake(address user, uint256 RNTAmount) internal {
        vm.startPrank(user);
        rnttoken.approve(address(rntstake), RNTAmount);
        rntstake.stake(RNTAmount);
        vm.stopPrank();
    }

    function test_unstake() public {
        uint256 price1 = 80_000_000 * 1e18;
        uint256 price2 = 20_000_000 * 1e18;
        _stake(stakeHolder1, price1);
        _stake(stakeHolder1, price2);
        vm.startPrank(stakeHolder1);
        vm.warp(block.timestamp + 2 days);
        rntstake.unstake(price2);
        assertEq(rntstake.amountOfStake(stakeHolder1), price1);
        assertEq(
            rntstake.mintableTokenOfStake(stakeHolder1),
            (price1 + price2) * 2
        );
        assertEq(rnttoken.balanceOf(stakeHolder1), price2);
        vm.stopPrank();
    }

    function test_claim() public {
        uint256 price1 = 80_000_000 * 1e18;
        uint256 price2 = 20_000_000 * 1e18;
        _stake(stakeHolder1, price1);
        vm.warp(block.timestamp + 2 days);
        _stake(stakeHolder1, price2);
        vm.startPrank(stakeHolder1);
        rntstake.claim();
        uint256 locked;
        uint256 unlock;
        assertEq(rntstake.mintableTokenOfStake(stakeHolder1), 0);
        vm.warp(block.timestamp + 1 days);

        (unlock, locked) = esrntotken.balanceOfLockedAndUnlock(stakeHolder1);
        assertEq(locked, price1 * 2/30);
        vm.stopPrank();

    }

    function test_exchange() public {

        uint256 price1 = 80_000_000 * 1e18;
        uint256 price2 = 20_000_000 * 1e18;
        _stake(stakeHolder1, price1);
        vm.warp(block.timestamp + 2 days);
        _stake(stakeHolder1, price2);
        vm.startPrank(stakeHolder1);
        rntstake.claim();
        vm.warp(block.timestamp + 2 days);
        rntstake.claim();
        vm.warp(block.timestamp + 29 days);
        uint256 locked;
        uint256 unlock;
        (unlock, locked) = esrntotken.balanceOfLockedAndUnlock(stakeHolder1);
        assertEq(unlock, price1*2);
        assertEq(locked, ((price1+price2)*2*29)/30);
        vm.stopPrank();
        vm.prank(owner);
        rnttoken.approve(address(rntstake), unlock+locked);
        vm.prank(stakeHolder1);
        rntstake.exchange(address(owner),unlock+locked);
        assertEq(rnttoken.balanceOf(stakeHolder1), unlock+locked);
    }

}
