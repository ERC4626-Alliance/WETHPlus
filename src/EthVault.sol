// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";

contract EthVault is ERC20 {

    constructor() ERC20("Wrapped Ether Plus", "WETH+", 18) {}

    function totalSupply() public view override returns (uint256) { return address(this).balance; }

    /*//////////////////////////////////////////////////////////////
                        ERC7575MinimalVault
    //////////////////////////////////////////////////////////////*/

    address public constant asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // EIP-7528: https://ercs.ethereum.org/ERCS/erc-7528

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    
    function share() external view returns (address) { return address(this); }
    
    function convertToShares(uint256 assets) external pure returns (uint256) { return assets; }
    
    function convertToAssets(uint256 shares) external pure returns (uint256) { return shares; }
    
    function totalAssets() external view returns (uint256) { return address(this).balance; }

    /*//////////////////////////////////////////////////////////////
                        ERC7575DepositVault
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256, address receiver) external payable returns (uint256 shares) {
        shares = msg.value;
        unchecked {
            balanceOf[receiver] += shares;    
        }
        emit Transfer(address(0), receiver, shares);
        emit Deposit(msg.sender, receiver, shares, shares);
    }

    function previewDeposit(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7575WithdrawVault
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares) {
        shares = assets;
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        balanceOf[owner] -= shares;

        emit Transfer(owner, address(0), shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        (bool success, ) = payable(msg.sender).call{value: shares}("");
        require(success);
    }

    function previewWithdraw(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return balanceOf[owner];
    }
}