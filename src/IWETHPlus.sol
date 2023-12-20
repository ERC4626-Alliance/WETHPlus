// SPDX-License-Identifier: MIT
pragma solidity >=0.8;


/// @notice Modern and gas efficient Wrapped Ether
/// @author ERC-4626 Alliance (https://github.com/ERC4626-Alliance/WETHPlus)
/// @author Modified from WETH9 (https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) and Solmate ERC20 and ERC4626 (https://github.com/transmissions11/solmate)

import "./Interfaces.sol";

interface IWETHPlus is IWETH9, IERC2612, IERC165, IERC7575MinimalVault, IERC7575DepositVault, IERC7575WithdrawVault {

    function withdrawAll(address receiver, address owner) external returns (uint256 shares);

    receive() external payable;
}
