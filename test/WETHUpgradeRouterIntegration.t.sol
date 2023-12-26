// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {WETHUpgradeRouter} from "../src/WETHUpgradeRouter.sol";
import "../src/IWETHPlus.sol";
import "../src/WETHPlus.sol";

contract WETHUpgradeRouterIntegrationTest is Test {
    WETHUpgradeRouter router;
    IWETHPlus wethPlus;
    IWETH9 constant WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant PERMIT2 = address(1);

    function setUp() public {
        wethPlus = IWETHPlus(payable(new WETHPlus()));
        router = new WETHUpgradeRouter(address(WETH9), payable(address(wethPlus)), PERMIT2);
    }

    function testWETH9Upgrade(address to, uint32 value) public {
        if (to == address(0)) {
            return;
        }
        WETH9.deposit{value: value}();
        WETH9.approve(address(router), type(uint256).max);
        assertEq(WETH9.balanceOf(address(this)), value);


        router.depositAll(to, 0, 0, 0, 0);
    }

    function testEthDeposit(address to, uint32 value) public {
        if (to == address(0)) {
            return;
        }
        router.depositAll{value: value}(to, 0, 0, 0, 0);
        assertEq(wethPlus.balanceOf(to), value);
    }
}
