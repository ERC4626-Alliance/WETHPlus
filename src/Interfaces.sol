// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

interface IERC20 {
    function name() external returns(string memory);
    function symbol() external returns(string memory);
    function decimals() external returns(uint8);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);

    function balanceOf(address owner) external returns (uint256);
    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IWETH9 is IERC20 {
    function withdraw(uint256 shares) external;
    function deposit() external payable;
}

interface IERC2612 {

    function nonces(address owner) external returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IERC4626 {

    function asset() external returns(address);

    function totalAssets() external view returns (uint256);

    function deposit(uint256, address receiver) external payable returns (uint256 shares);

    function mint(uint256, address receiver) external payable returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
    
    function convertToShares(uint256 assets) external pure returns (uint256 shares);

    function convertToAssets(uint256 shares) external pure returns (uint256 assets);

    function previewDeposit(uint256 assets) external pure returns (uint256 shares);

    function previewMint(uint256 shares) external pure returns (uint256 assets);

    function previewWithdraw(uint256 assets) external pure returns (uint256 shares);

    function previewRedeem(uint256 shares) external pure returns (uint256 assets);

    function maxDeposit(address) external pure returns (uint256);

    function maxMint(address) external pure returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);
}