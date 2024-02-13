// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {WETHUpgradeRouter} from "../src/WETHUpgradeRouter.sol";
import "../src/IWETHPlus.sol";
import "../src/WETHPlus.sol";

contract WETHUpgradeRouterTest is Test {
    WETHUpgradeRouter router;
    IWETHPlus wethPlus;
    IWETH9 weth9;
    address constant PERMIT2 = address(1);

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        weth9 = IWETH9(payable(new WETHPlus()));
        wethPlus = IWETHPlus(payable(new WETHPlus()));
        router = new WETHUpgradeRouter(address(weth9), payable(address(wethPlus)), PERMIT2);
    }

    function testConstants() public {
        assertEq(router.asset(), address(weth9));
        assertEq(router.share(), address(wethPlus));
        assertEq(router.totalAssets(), 0);
        assertEq(router.PERMIT2(), PERMIT2);
    }

    function testConvertToShares(uint256 assets) public {
        assertEq(router.convertToShares(1e18), 1e18);
        assertEq(router.convertToShares(assets), assets);
    }

    function testConvertToAssets(uint256 shares) public {
        assertEq(router.convertToAssets(1e18), 1e18);
        assertEq(router.convertToAssets(shares), shares);
    }

    function testERC165() public {
        assertTrue(router.supportsInterface(0x01ffc9a7));
        assertTrue(router.supportsInterface(0x50a526d6));
        assertTrue(router.supportsInterface(0xc1f329ef));
        assertFalse(router.supportsInterface(0xffffffff));
    }

    function testMaxDeposit(address from) public {
        assertEq(router.maxDeposit(from), type(uint256).max);
    }

    function testPreviewDeposit(uint256 amount) public {
        assertEq(router.previewDeposit(amount), amount);
    }

    function testDeposit(uint256 amount, address to) public {
        amount = bound(amount, 0, address(this).balance);

        weth9.deposit{value:amount}();
        weth9.approve(address(router), amount);

        assertEq(router.deposit(amount, to), amount);
        assertEq(weth9.balanceOf(to), 0);
        assertEq(weth9.allowance(address(this), address(router)), 0);
        assertEq(wethPlus.balanceOf(to), amount);
    }

    function testDepositAllNoPermit(uint256 amount, address to, uint256 timestamp) public {
        amount = bound(amount, 0, address(this).balance);
        timestamp = bound(timestamp, 0, block.timestamp - 1);

        weth9.deposit{value:amount}();
        weth9.approve(address(router), amount);

        assertEq(router.depositAll(to, timestamp, 0, 0, 0), amount);
        assertEq(weth9.balanceOf(to), 0);
        assertEq(weth9.allowance(address(this), address(router)), 0);
        assertEq(wethPlus.balanceOf(to), amount);
    }

    function testDepositAllWithPermit(uint248 privateKey, uint256 amount, address to, uint256 timestamp) public {
        amount = bound(amount, 0, address(this).balance);
        timestamp = bound(timestamp, block.timestamp, type(uint256).max);
        if (privateKey == 0) privateKey = 1;

        
        address owner = vm.addr(privateKey);

        weth9.deposit{value:amount}();
        weth9.transfer(owner, amount);

        vm.startPrank(owner);
        weth9.approve(address(router), amount);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    wethPlus.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, PERMIT2, type(uint256).max, 0, timestamp))
                )
            )
        );

        assertEq(router.depositAll(to, timestamp, v, r, s), amount);
        
        assertEq(weth9.balanceOf(to), 0);
        assertEq(weth9.allowance(owner, address(router)), 0);
        assertEq(wethPlus.balanceOf(to), amount);
        assertEq(wethPlus.allowance(owner, PERMIT2), type(uint256).max);
    }

    function testDepositAllWithPermitFrontrun(uint248 privateKey, uint256 amount, address to, uint256 timestamp) public {
        amount = bound(amount, 0, address(this).balance);
        timestamp = bound(timestamp, block.timestamp, type(uint256).max);
        if (privateKey == 0) privateKey = 1;

        
        address owner = vm.addr(privateKey);

        weth9.deposit{value:amount}();
        weth9.transfer(owner, amount);

        vm.startPrank(owner);
        weth9.approve(address(router), amount);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    wethPlus.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, PERMIT2, type(uint256).max, 0, timestamp))
                )
            )
        );

        wethPlus.permit(owner, PERMIT2, type(uint256).max, timestamp, v, r, s);

        assertEq(router.depositAll(to, timestamp, v, r, s), amount);
        
        assertEq(weth9.balanceOf(to), 0);
        assertEq(weth9.allowance(owner, address(router)), 0);
        assertEq(wethPlus.balanceOf(to), amount);
        assertEq(wethPlus.allowance(owner, PERMIT2), type(uint256).max);
    }
}
