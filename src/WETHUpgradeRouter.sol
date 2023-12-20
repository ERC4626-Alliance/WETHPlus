// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Upgrade Contract from WETH9 to WETH+
/// @author ERC-4626 Alliance (https://github.com/ERC4626-Alliance/WETHPlus)
/// @author Modified from WETH9 (https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) and Solmate ERC20 and ERC4626 (https://github.com/transmissions11/solmate)

import "./Interfaces.sol";
import "./IWETHPlus.sol";

contract WETHUpgradeRouter {

    address public immutable PERMIT2;

    constructor (address weth9, address payable wethPlus, address permit2) {
        asset = weth9;
        share = wethPlus;
        PERMIT2 = permit2;
    }

    receive() external payable {}

    function depositAll(
        address to, 
        uint256 deadline, 
        uint8 v,
        bytes32 r,
        bytes32 s 
    ) public payable returns (uint256 shares) {
        
        // If the user passes in a permit of permit2, then attempt to execute it
        if (deadline >= block.timestamp) {
            IWETHPlus(share).permit(msg.sender, PERMIT2, type(uint256).max, deadline, v, r, s);
        }

        // Withdraw all WETH9 balance of caller
        uint256 weth9Amount = IWETH9(asset).balanceOf(msg.sender);
        return deposit(weth9Amount, to);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7575MinimalVault
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    address public immutable asset;

    address payable public immutable share;

    uint256 public constant totalAssets = 0;
        
    function convertToShares(uint256 assets) external pure returns (uint256) { return assets; }
    
    function convertToAssets(uint256 shares) external pure returns (uint256) { return shares; }

    /*//////////////////////////////////////////////////////////////
                        ERC7575DepositVault
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount, address to) public returns (uint256 shares) {
        
        IWETH9(asset).transferFrom(msg.sender, address(this), amount);
        IWETH9(asset).withdraw(amount);

        shares = amount;
        
        require(IWETHPlus(share).deposit{value: amount}(0, to) == shares);
    }

    function previewDeposit(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // EIP165
                || interfaceId == 0x50a526d6 // ERC7575MinimalVault
                || interfaceId == 0xc1f329ef; // ERC7575DepositVault
    }
}