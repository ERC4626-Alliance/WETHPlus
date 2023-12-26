# WETH+ • [![CI](https://github.com/transmissions11/foundry-template/actions/workflows/tests.yml/badge.svg)](https://github.com/transmissions11/foundry-template/actions/workflows/tests.yml)

A new version of WETH powered by [ERC-7535](https://ercs.ethereum.org/ERCS/erc-7535), [ERC-2612](https://ercs.ethereum.org/ERCS/erc-2612) message signing, and [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) transient storage

Telegram Discussion: https://t.me/weth99

Specs:
- Compiled feedback: https://docs.google.com/document/d/1F4JZMijfHGM7d0gkCYeSg9VFdgLkJSUn5kxf16uvVvY/edit
- Initial Spec: https://hackmd.io/kXK-UqS9RtGOKmdVu50rwg

## Test Coverage

| File                      | % Lines         | % Statements    | % Branches     | % Funcs         |
|---------------------------|-----------------|-----------------|----------------|-----------------|
| src/ERC20.sol             | 90.48% (19/21)  | 91.67% (22/24)  | 100.00% (6/6)  | 83.33% (5/6)    |
| src/EthVault.sol          | 100.00% (22/22) | 100.00% (25/25) | 100.00% (6/6)  | 100.00% (11/11) |
| src/WETHPlus.sol          | 100.00% (21/21) | 100.00% (28/28) | 100.00% (8/8)  | 100.00% (4/4)   |
| src/WETHUpgradeRouter.sol | 100.00% (15/15) | 100.00% (20/20) | 50.00% (1/2)   | 100.00% (7/7)   |
| Total                     | 97.47% (77/79)  | 97.94% (95/97)  | 95.45% (21/22) | 96.43% (27/28)  |

## Contributing

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

### Setup

```sh
git clone git@github.com:ERC4626-Alliance/WETHPlus.git
cd WETHPlus
forge install
```

### Run Tests

```sh
forge test
```
