pragma solidity 0.8.15;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {DSInvariantTest} from "solmate/test/utils/DSInvariantTest.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {WETHPlus} from "../src/WETHPlus.sol";

contract WETHPlusTest is DSTestPlus {
    WETHPlus vault;

    function setUp() public {
        vault = new WETHPlus();
    }
    
    receive() external payable {}
 
    function testERC165() public {
        assertTrue(vault.supportsInterface(0x01ffc9a7));
        assertTrue(vault.supportsInterface(0x50a526d6));
        assertTrue(vault.supportsInterface(0xc1f329ef));
        assertTrue(vault.supportsInterface(0x70dec094));
        assertFalse(vault.supportsInterface(0xffffffff));
    }

    function testDeposit(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);

        vault.deposit{value: amount}();
        assertEq(vault.balanceOf(address(this)), amount);
    }

    function testReceive(uint256 amount) public {
        amount = bound(amount, 1, address(this).balance);

        address(vault).call{value: amount}("");
        assertEq(vault.balanceOf(address(this)), amount);
    }

    // TODO
    function testFailFallback() public {}

    // TODO make sure all to addresses dont have a fallback function
    function testWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);

        testDeposit(depositAmount);

        vault.withdraw(withdrawAmount);
        assertEq(vault.balanceOf(address(this)), depositAmount - withdrawAmount);
    }

    function testWithdrawAll(uint256 amount, address from, address to) public {
        amount = bound(amount, 0, address(this).balance);
        hevm.assume(from != to);
        
        uint256 ethBefore = to.balance;

        testDeposit(amount);
        vault.transfer(from, amount);

        hevm.prank(from);
        vault.approve(to, amount);

        hevm.startPrank(to);
        assertEq(vault.withdrawAll(to, from), amount);
        assertEq(vault.balanceOf(from), 0);
        assertEq(to.balance, ethBefore + amount);
        assertEq(vault.allowance(from, to), 0);
    }

    function testWithdrawAllMaxApproval(uint256 amount, address from, address to) public {
        amount = bound(amount, 0, address(this).balance);
        hevm.assume(from != to);
        
        uint256 ethBefore = to.balance;

        testDeposit(amount);
        vault.transfer(from, amount);

        hevm.prank(from);
        vault.approve(to, type(uint256).max);

        hevm.startPrank(to);
        assertEq(vault.withdrawAll(to, from), amount);
        assertEq(vault.balanceOf(from), 0);
        assertEq(to.balance, ethBefore + amount);
        assertEq(vault.allowance(from, to), type(uint256).max);
    }

    function testFailWithdrawWithoutCallSuccess(uint256 withdrawAmount) public {
        withdrawAmount = bound(withdrawAmount, 0, address(this).balance);

        testDeposit(withdrawAmount);

        address receiver = address(new MockERC20("token", "TKN", 18));
        vault.transfer(receiver, withdrawAmount);

        hevm.prank(receiver);
        vault.withdraw(withdrawAmount);
    }

    function testFailWithdrawAllWithoutCallSuccess(uint256 withdrawAmount) public {
        withdrawAmount = bound(withdrawAmount, 0, address(this).balance);

        testDeposit(withdrawAmount);

        address receiver = address(new MockERC20("token", "TKN", 18));

        vault.withdrawAll(receiver, address(this));
    }

    function testFailWithdrawAllWithoutEnoughApproval(uint256 amount, address from, address to) public {
        amount = bound(amount, 1, address(this).balance);
        hevm.assume(from != to);

        testDeposit(amount);
        vault.transfer(from, amount);

        hevm.prank(from);
        vault.approve(to, amount - 1);

        hevm.startPrank(to);
        vault.withdrawAll(to, from);
    }
}