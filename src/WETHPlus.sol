// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Modern and gas efficient Wrapped Ether
/// @author ERC-4626 Alliance (https://github.com/ERC4626-Alliance/WETHPlus)
/// @author Modified from WETH9 (https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) and Solmate ERC20 and ERC4626 (https://github.com/transmissions11/solmate)

contract WETHPlus {
    string public constant name = "Wrapped Ether Plus";
    string public constant symbol = "WETH+";
    uint8 public constant decimals = 18;
    address public constant asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // EIP-7528: https://ercs.ethereum.org/ERCS/erc-7528

    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;


    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        unchecked {
            balanceOf[msg.sender] += msg.value;
        }
        emit Transfer(address(0), msg.sender, msg.value);
        emit Deposit(msg.sender, msg.sender, msg.value, msg.value);
    }

    function deposit(uint256, address receiver) external payable returns (uint256 shares) {
        shares = msg.value;
        unchecked {
            balanceOf[receiver] += shares;    
        }
        emit Transfer(address(0), receiver, shares);
        emit Deposit(msg.sender, receiver, shares, shares);
    }

    function mint(uint256, address receiver) external payable returns (uint256 assets) {
        assets = msg.value;
        unchecked {
            balanceOf[receiver] += assets;    
        }
        emit Transfer(address(0), receiver, assets);
        emit Deposit(msg.sender, receiver, assets, assets);
    }

    function withdraw(uint256 shares) public {
        balanceOf[msg.sender] -= shares;
        emit Transfer(msg.sender, address(0), shares);
        emit Withdraw(msg.sender, msg.sender, msg.sender, shares, shares);

        (bool success, ) = payable(msg.sender).call{value: shares}("");
        require(success);
    }

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

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        assets = shares;
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

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function totalAssets() external view returns (uint256) {
        return address(this).balance;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        // Cannot overflow because the sum of all eth can't exceed uint 256
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all eth can't exceed uint 256
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function convertToShares(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function convertToAssets(uint256 shares) external pure returns (uint256 assets) {
        assets = shares;
    }

    function previewDeposit(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function previewMint(uint256 shares) external pure returns (uint256 assets) {
        assets = shares;
    }

    function previewWithdraw(uint256 assets) external pure returns (uint256 shares) {
        shares = assets;
    }

    function previewRedeem(uint256 shares) external pure returns (uint256 assets) {
        assets = shares;
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return balanceOf[owner];
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf[owner];
    }
}