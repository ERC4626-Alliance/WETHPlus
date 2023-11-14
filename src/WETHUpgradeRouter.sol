// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Upgrade Contract from WETH9 to WETH+
/// @author ERC-4626 Alliance (https://github.com/ERC4626-Alliance/WETHPlus)
/// @author Modified from WETH9 (https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) and Solmate ERC20 and ERC4626 (https://github.com/transmissions11/solmate)

import "./Interfaces.sol";
import "./IWETHPlus.sol";

contract WETHUpgradeRouter {

    IWETH9 public immutable WETH9;

    IWETHPlus public immutable WETHPlus;

    address public immutable PERMIT2;

    constructor (IWETHPlus wethPlus, IWETH9 weth9, address permit2) {
        WETHPlus = wethPlus;
        WETH9 = weth9;
        PERMIT2 = permit2;
    }

    receive() external payable {}

    /// @dev function naming used for ERC-4626 compatibility
    function deposit(uint256 amount, address to) public returns (uint256 shares) {
        WETH9.transferFrom(msg.sender, address(this), amount);
        WETH9.withdraw(amount);

        shares = amount;
        
        require(WETHPlus.deposit{value: amount}(0, to) == shares);
    }

    function depositAll(
        address to, 
        uint256 deadline, 
        uint8 v,
        bytes32 r,
        bytes32 s 
    ) public payable returns (uint256 shares) {

        // Withdraw all WETH9 balance of caller
        uint256 weth9Amount = WETH9.balanceOf(msg.sender);
        if (weth9Amount != 0) {
            WETH9.transferFrom(msg.sender, address(this), weth9Amount);
            WETH9.withdraw(weth9Amount);
        }

        // Combined amount for deposit
        shares = weth9Amount + msg.value;
        
        // complete the deposit to the target address. The amount parameter is ignored by WETH+ in favor of the msg.value
        require(WETHPlus.deposit{value: shares}(0, to) == shares);

        // If the user passes in a permit of permit2, then attempt to execute it
        if (deadline >= block.timestamp) {
            _maxPermit2(deadline, v, r, s);
        }
    }

    function _maxPermit2(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        WETHPlus.permit(msg.sender, PERMIT2, type(uint256).max, deadline, v, r, s);
    }
}