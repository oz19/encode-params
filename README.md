# Encode Parameters

Didactic contract demonstrating `abi.encodePacked` usage patterns found across DeFi protocols: pool identifiers, trading positions, swap routes, limit orders, flash loans, yield strategies, cross-chain bridge data and order types.

## Contract

`AbiEncoderDemo.sol`

| Function | Description |
|---|---|
| `createPoolIdentifier(tokenA, tokenB, fee)` | Sorts tokens and returns a unique keccak256 pool id. |
| `encodeTradingPosition(user, tokenIn, tokenOut, amountIn, minOut, deadline)` | Returns packed position bytes and their keccak256 id. |
| `encodeSwapData(path[], amount[], deadline)` | Packs a multi-hop swap route. `path` and `amount` must be the same length. |
| `encodeLimitOrder(maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce)` | Returns packed order bytes and their keccak256 hash. |
| `encodeYieldPosition(user, poolId, amount, startTime)` | Returns a keccak256 yield farming position id. |
| `encodeFlashLoan(token, amount, callbackData)` | Packs flash loan parameters with version tag. |
| `encodeStakingPoolConfig(token, rewardRate, lockPeriod, maxStakers)` | Packs staking pool config including `block.timestamp`. |
| `createUserMultiPoolHash(user, poolIds[])` | Hashes a user address together with any number of pool ids. |
| `encodeYieldStrategy(name, pools[], weighs[])` | Packs a named strategy. `pools` and `weighs` must be the same length. |
| `encodeCrossChainBridgeData(srcChain, dstChain, token, amount, recipient)` | Packs bridge transfer parameters. |
| `createDeFiTransactionId(txType, user, timestamp, nonce)` | Returns a keccak256 transaction id. |
| `encodeStopLossOrder(user, token, amount, stopPrice, triggerPrice)` | Packs stop-loss order parameters. |
| `encodeTakeProfitOrder(user, token, amount, takeProfitPrice)` | Packs take-profit order parameters. |
| `encodeTrailingStopOrder(user, token, amount, trailingPercent, activationPrice)` | Packs trailing-stop order parameters. |

## Hash collision note

`abi.encodePacked` concatenates arguments without length prefixes. For functions that accept dynamic types (`string`, `bytes`, `address[]`, `uint256[]`), different inputs can produce identical packed output. These functions are for demonstration purposes; production contracts that need collision-resistant identifiers should use `abi.encode` instead.

## Usage

```shell
forge build
forge test
forge coverage
```
