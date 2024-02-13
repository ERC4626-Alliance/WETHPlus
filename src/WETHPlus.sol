// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./EthVault.sol";

/**
 @notice Modern and gas efficient Wrapped Ether
 @author ERC-4626 Alliance (https://github.com/ERC4626-Alliance/WETHPlus)
 @author Modified from WETH9 (https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) and Solmate ERC20 and ERC4626 (https://github.com/transmissions11/solmate)

 WETHPlus Inheritance Hierarchy ("+" denotes implemented functionality, "x" denotes an extended contract):

 WETHPlus
     +-- withdrawAll() and receive()
     +-- WETH9 backwards compatibility
     +-- ERC165
     x-- EthVault (ERC-4626 Vault Functionality)
         +-- ERC7575MinimalVault
         +-- ERC7575DepositVault
         +-- ERC7575WithdrawVault
         x-- ERC20
             +-- ERC2612
*/
contract WETHPlus is EthVault {

    receive() external payable {
        deposit();
    }

    function withdrawAll(address receiver, address owner) external payable returns (uint256 shares) {
        shares = balanceOf[owner]; 

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        balanceOf[owner] -= shares;

        emit Transfer(owner, address(0), shares);
        emit Withdraw(msg.sender, receiver, owner, shares, shares);

        (bool success, ) = payable(receiver).call{value: shares}("");
        require(success);
    }

    /*//////////////////////////////////////////////////////////////
                        WETH9 Backwards Compatibility
    //////////////////////////////////////////////////////////////*/

    function deposit() public payable {
        unchecked {
            balanceOf[msg.sender] += msg.value;
        }

        emit Transfer(address(0), msg.sender, msg.value);
        emit Deposit(msg.sender, msg.sender, msg.value, msg.value);
    }

    function withdraw(uint256 shares) public {
        balanceOf[msg.sender] -= shares;

        emit Transfer(msg.sender, address(0), shares);
        emit Withdraw(msg.sender, msg.sender, msg.sender, shares, shares);

        (bool success, ) = payable(msg.sender).call{value: shares}("");
        require(success);
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // EIP165
                || interfaceId == 0x50a526d6 // ERC7575MinimalVault
                || interfaceId == 0xc1f329ef // ERC7575DepositVault
                || interfaceId == 0x70dec094; // ERC7575WithdrawVault
    }
}
