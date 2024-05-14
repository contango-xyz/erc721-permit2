# ERC721 permit2

ERC721Permit2 applies the ideas from [ERC20 Permit2](https://github.com/Uniswap/permit2) to NFT contract, introducing a low-overhead, next-generation NFT approval/meta-tx system to make NFT approvals easier, more secure, and more consistent across applications.

## Features

- **Signature Based Approvals**: Any ERC721 token, can now use permit style approvals. This allows applications to have a single transaction flow by sending a permit signature along with the transaction data when using `ERC721Permit2` integrated contracts.
- **Batched Token Approvals**: Set permissions on different tokens to different spenders with one signature.
- **Signature Based Token Transfers**: Owners can sign messages to transfer tokens directly to signed spenders, bypassing setting any allowance. This means that approvals aren't necessary for applications to receive tokens and that there will never be hanging approvals when using this method. The signature is valid only for the duration of the transaction in which it is spent.
- **Batched Token Transfers**: Transfer different tokens to different recipients with one signature.
- **Signature Verification for Contracts**: All signature verification supports [EIP-1271](https://eips.ethereum.org/EIPS/eip-1271) so contracts can approve tokens and transfer tokens through signatures.
- **Non-monotonic Replay Protection**: Signature based transfers use unordered, non-monotonic nonces so that signed permits do not need to be transacted in any particular order.
- **Expiring Approvals**: Approvals can be time-bound, removing security concerns around hanging approvals on a wallet’s entire token balance. This also means that revoking approvals do not necessarily have to be a new transaction since an approval that expires will no longer be valid.
- **Batch Revoke Allowances**: Remove allowances on any number of tokens and spenders in one transaction.

## Integrating with Permit2

Before integrating, contracts can request users’ tokens through `ERC721Permit2`, users must approve the `ERC721Permit2` contract through the specific token contract. There's no tech docs, but being a derivation from Uniswap's Permit2, you should get a very good idea by looking at Uniswap's [documentation site](https://docs.uniswap.org/contracts/permit2/overview).


## Contributing

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

### Setup

```sh
git clone https://github.com/contango-xyz/erc721-permit2.git
cd erc721-permit2
forge install
```

### Lint

```sh
forge fmt [--check]
```

### Run Tests

```sh
# unit
forge test
```

### Deploy

Run the command below. Remove `--broadcast`, `---rpc-url`, `--private-key` and `--verify` options to test locally

```sh
forge script --broadcast --rpc-url <RPC-URL> --private-key <PRIVATE_KEY> --verify script/Deploy.s.sol
```

## Acknowledgments

Inspired by [ERC20 Permit2](https://github.com/Uniswap/permit2).

## Audits

Audited by Offbeat Security, report can be found in the `audits` folder or [here](https://hackmd.io/@devtooligan/erc721permit2-contango-11MAY2024)