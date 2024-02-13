pragma solidity 0.8.15;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {DSInvariantTest} from "solmate/test/utils/DSInvariantTest.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {EthVault} from "../src/EthVault.sol";

contract EthVaultTest is DSTestPlus {
    EthVault vault;

    function setUp() public {
        vault = new EthVault();
    }
    
    receive() external payable {}
 
    function testConstants() public {
        assertEq(vault.asset(), 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        assertEq(vault.share(), address(vault));
    }

    function testConvertToShares(uint256 assets) public {
        assertEq(vault.convertToShares(1e18), 1e18);
        assertEq(vault.convertToShares(assets), assets);
    }

    function testConvertToAssets(uint256 shares) public {
        assertEq(vault.convertToAssets(1e18), 1e18);
        assertEq(vault.convertToAssets(shares), shares);
    }

    function testTotals(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);

        vault.deposit{value: depositAmount}(0, address(this));

        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.totalSupply(), depositAmount);

        vault.withdraw(withdrawAmount, address(this), address(this));

        assertEq(vault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(vault.totalSupply(), depositAmount - withdrawAmount);
    }

    function testMaxDeposit(address from) public {
        assertEq(vault.maxDeposit(from), type(uint256).max);
    }

    function testPreviewDeposit(uint256 amount) public {
        assertEq(vault.previewDeposit(amount), amount);
    }

    function testDeposit(uint256 amount, address to) public {
        amount = bound(amount, 0, address(this).balance);

        assertEq(vault.deposit{value: amount}(0, to), amount);
        assertEq(vault.balanceOf(to), amount);
    }

    function testMaxWithdraw(uint256 amount, address from) public {
        amount = bound(amount, 0, address(this).balance);

        testDeposit(amount, from);
        assertEq(vault.maxWithdraw(from), amount);
    }

    function testPreviewWithdraw(uint256 amount) public {
        assertEq(vault.previewWithdraw(amount), amount);
    }

    function testWithdraw(uint256 depositAmount, uint256 withdrawAmount, address to) public {
        
        (bool success, ) = to.call{value: 1}("");
        hevm.assume(success);
        hevm.prank(to);
        address(this).call{value: 1}("");
        
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);

        testDeposit(depositAmount, to);

        hevm.startPrank(to);
        assertEq(vault.withdraw(withdrawAmount, to, to), withdrawAmount);
        assertEq(vault.balanceOf(to), depositAmount - withdrawAmount);
    }

    function testWithdrawFrom(uint256 depositAmount, uint256 withdrawAmount, address from, address to) public {
        (bool success, ) = to.call{value: 1}("");
        hevm.assume(success);
        hevm.prank(to);
        address(this).call{value: 1}("");
        
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);
        hevm.assume(from != to);
        
        uint256 ethBefore = to.balance;

        testDeposit(depositAmount, from);

        hevm.prank(from);
        vault.approve(to, withdrawAmount);

        hevm.startPrank(to);
        assertEq(vault.withdraw(withdrawAmount, to, from), withdrawAmount);
        assertEq(vault.balanceOf(from), depositAmount - withdrawAmount);
        assertEq(to.balance, ethBefore + withdrawAmount);
        assertEq(vault.allowance(from, to), 0);
    }

    function testWithdrawFromMaxApproval(uint256 depositAmount, uint256 withdrawAmount, address from, address to) public {
        (bool success, ) = to.call{value: 1}("");
        hevm.assume(success);
        hevm.prank(to);
        address(this).call{value: 1}("");
        
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);
        hevm.assume(from != to);

        uint256 ethBefore = to.balance;

        testDeposit(depositAmount, from);

        hevm.prank(from);
        vault.approve(to, type(uint256).max);

        hevm.startPrank(to);
        assertEq(vault.withdraw(withdrawAmount, to, from), withdrawAmount);
        assertEq(vault.balanceOf(from), depositAmount - withdrawAmount);
        assertEq(to.balance, ethBefore + withdrawAmount);
        assertEq(vault.allowance(from, to), type(uint256).max);
    }

    function testFailWithdrawWithoutCallSuccess(uint256 withdrawAmount) public {
        withdrawAmount = bound(withdrawAmount, 0, address(this).balance);

        testDeposit(address(this).balance, address(this));

        address receiver = address(new MockERC20("token", "TKN", 18));

        vault.withdraw(withdrawAmount, receiver, address(this));
    }

    function testFailWithdrawWithoutEnoughDeposits(uint256 withdrawAmount) public {
        withdrawAmount = bound(withdrawAmount, address(this).balance + 1, type(uint256).max);

        testDeposit(address(this).balance, address(this));

        vault.withdraw(withdrawAmount, address(this), address(this));
    }

    function testFailWithdrawWithoutEnoughApproval(uint256 amount, address from, address to) public {
        amount = bound(amount, 1, address(this).balance);
        hevm.assume(from != to);

        testDeposit(amount, from);

        hevm.prank(from);
        vault.approve(to, amount - 1);

        hevm.startPrank(to);
        vault.withdraw(amount, to, from);
    }
}