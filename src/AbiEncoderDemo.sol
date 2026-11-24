// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/**
 * @title AbiEncoderDemo
 * @notice Demonstrates common uses of `abi.encodePacked` found in DeFi protocols:
 *         pool identifiers, trading positions, swap data, limit orders, yield farming,
 *         flash loans, staking pools, bridge data and order types.
 * @dev `abi.encodePacked` concatenates arguments tightly with no length prefixes.
 *      When dynamic types (string, bytes, arrays) are mixed, the same packed output
 *      can be produced by different inputs — do not rely on these hashes for security-
 *      critical uniqueness guarantees in production code.
 */
contract AbiEncoderDemo {

    /// @notice Emitted when arbitrary data is encoded and hashed.
    event DataEncoded(bytes32 indexed hash, bytes encodedData);

    /// @notice Emitted when a new pool identifier is created.
    event PoolIdentifierCreated(bytes32 indexed poolId, address token, uint256 rate);

    /// @notice Emitted when a new user position is created.
    event UserPositionCreated(bytes32 indexed positionId, address user, uint256 amount);

    /**
     * @notice Creates a deterministic pool identifier from two token addresses and a fee tier.
     * @dev Tokens are sorted (lower address first) so the identifier is order-independent.
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param fee Pool fee tier (e.g. 500 = 0.05%, 3000 = 0.3%).
     * @return poolId Unique keccak256 identifier for this pool.
     */
    function createPoolIdentifier(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns(bytes32 poolId) {
        (address token0, address token1) = (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
        poolId = keccak256(abi.encodePacked(token0, token1, fee));
    }

    /**
     * @notice Encodes a trading position and returns its unique identifier.
     * @param user User opening the position.
     * @param tokenIn Token used to open the position.
     * @param tokenOut Token received.
     * @param amountIn Input amount.
     * @param minAmountOut Minimum acceptable output amount.
     * @param deadline Maximum timestamp for the transaction.
     * @return positionId Unique keccak256 identifier for this position.
     * @return encodedData Raw packed encoding of all position parameters.
     */
    function encodeTradingPosition(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external pure returns(bytes32 positionId, bytes memory encodedData) {
        encodedData = abi.encodePacked(user, tokenIn, tokenOut, amountIn, minAmountOut, deadline);
        positionId = keccak256(encodedData);
    }

    /**
     * @notice Encodes a multi-hop swap: concatenated token path, amounts and deadline.
     * @dev `path` and `amount` must have the same length.
     * @param path Ordered array of token addresses for the swap route.
     * @param amount Corresponding amount for each hop.
     * @param deadline Maximum timestamp for the transaction.
     * @return swapData Packed encoding of path, amounts and deadline.
     */
    function encodeSwapData(
        address[] calldata path,
        uint256[] calldata amount,
        uint256 deadline
    ) external pure returns(bytes memory swapData) {
        require(path.length == amount.length, "Arrays must have the same size");

        bytes memory pathData;
        for (uint i = 0; i < path.length; i++) {
            pathData = abi.encodePacked(pathData, path[i]);
        }

        bytes memory amountData;
        for (uint i = 0; i < amount.length; i++) {
            amountData = abi.encodePacked(amountData, amount[i]);
        }

        swapData = abi.encodePacked(pathData, amountData, deadline);
    }

    /**
     * @notice Encodes a limit order and returns its hash.
     * @param maker Order creator.
     * @param taker Designated counterparty (or zero address for open).
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param amountIn Input amount.
     * @param amountOut Expected output amount.
     * @param nonce Unique nonce to prevent replay.
     * @return orderHash keccak256 hash of the encoded order.
     * @return orderData Raw packed order bytes.
     */
    function encodeLimitOrder(
        address maker,
        address taker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 nonce
    ) external pure returns(bytes32 orderHash, bytes memory orderData) {
        orderData = abi.encodePacked(
            maker,
            taker,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            nonce,
            "ORDER_DATA_V1"
        );
        orderHash = keccak256(orderData);
    }

    /**
     * @notice Encodes a yield farming position identifier.
     * @param user User address.
     * @param poolId Pool identifier (from createPoolIdentifier).
     * @param amount Staked amount.
     * @param startTime Staking start timestamp.
     * @return positionId Unique keccak256 identifier for this yield position.
     */
    function encodeYieldPosition(
        address user,
        bytes32 poolId,
        uint256 amount,
        uint256 startTime
    ) external pure returns(bytes32 positionId) {
        positionId = keccak256(abi.encodePacked(user, poolId, amount, startTime, "YIELD_POSITION"));
    }

    /**
     * @notice Encodes flash loan parameters.
     * @param token Token to borrow.
     * @param amount Borrow amount.
     * @param callbackData Arbitrary data forwarded to the borrower callback.
     * @return flashLoanData Packed encoding of token, amount, callbackData and version tag.
     */
    function encodeFlashLoan(
        address token,
        uint256 amount,
        bytes calldata callbackData
    ) external pure returns(bytes memory flashLoanData) {
        flashLoanData = abi.encodePacked(token, amount, callbackData, "FLASH_LOAN_V1");
    }

    /**
     * @notice Encodes the configuration for a staking pool at the current block timestamp.
     * @param token Staking token address.
     * @param rewardRate Reward rate (units depend on the staking implementation).
     * @param lockPeriod Lock period in seconds.
     * @param maxStakers Maximum number of concurrent stakers.
     * @return poolConfig Packed encoding including the current block timestamp.
     */
    function encodeStakingPoolConfig(
        address token,
        uint256 rewardRate,
        uint256 lockPeriod,
        uint256 maxStakers
    ) external view returns(bytes memory poolConfig) {
        poolConfig = abi.encodePacked(
            token,
            rewardRate,
            lockPeriod,
            maxStakers,
            block.timestamp
        );
    }

    /**
     * @notice Creates a hash that uniquely identifies a user across multiple pools.
     * @param user User address.
     * @param poolIds Array of pool identifiers the user participates in.
     * @return userHash keccak256 hash of the user address concatenated with all pool ids.
     */
    function createUserMultiPoolHash(
        address user,
        bytes32[] calldata poolIds
    ) external pure returns(bytes32 userHash) {
        bytes memory data = abi.encodePacked(user);

        for (uint256 i = 0; i < poolIds.length; i++){
            data = abi.encodePacked(data, poolIds[i]);
        }

        data = abi.encodePacked(data, "MULTI_POOL_USER");
        userHash = keccak256(data);
    }

    /**
     * @notice Encodes a yield strategy definition: name, pool addresses and their weights.
     * @dev `pools` and `weighs` must have the same length.
     * @param strategyName Human-readable strategy name.
     * @param pools Array of pool addresses included in the strategy.
     * @param weighs Corresponding weight for each pool (units defined by the strategy).
     * @return strategyData Packed encoding of name, pools, weights and version tag.
     */
    function encodeYieldStrategy(
        string calldata strategyName,
        address[] calldata pools,
        uint256[] calldata weighs
    ) external pure returns(bytes memory strategyData) {
        require(pools.length == weighs.length, "Array length must be equal");

        bytes memory nameData = abi.encodePacked(strategyName);

        bytes memory poolsData;
        for (uint i = 0; i < pools.length; i++ ) {
            poolsData = abi.encodePacked(poolsData, pools[i]);
        }

        bytes memory weighsData;
        for (uint i = 0; i < weighs.length; i++) {
            weighsData = abi.encodePacked(weighsData, weighs[i]);
        }

        strategyData = abi.encodePacked(nameData, poolsData, weighsData, "YIELD_STRATEGY_V1");
    }

    /**
     * @notice Encodes cross-chain bridge transfer data.
     * @param sourceChain Source chain ID.
     * @param targetChain Destination chain ID.
     * @param token Token to transfer.
     * @param amount Transfer amount.
     * @param recipient Recipient address on the target chain.
     * @return bridgeData Packed encoding of all bridge parameters.
     */
    function encodeCrossChainBridgeData(
        uint256 sourceChain,
        uint256 targetChain,
        address token,
        uint256 amount,
        address recipient
    ) external pure returns (bytes memory bridgeData) {
        bridgeData = abi.encodePacked(
            sourceChain,
            targetChain,
            token,
            amount,
            recipient,
            "CROSS_CHAIN_BRIDGE"
        );
    }

    /**
     * @notice Creates a unique identifier for a DeFi transaction.
     * @param txType Human-readable transaction type label.
     * @param user Transaction initiator.
     * @param timestamp Transaction timestamp.
     * @param nonce Unique nonce to prevent replay.
     * @return txId keccak256 identifier for this transaction.
     */
    function createDeFiTransactionId(
        string calldata txType,
        address user,
        uint256 timestamp,
        uint256 nonce
    ) external pure returns (bytes32 txId) {
        txId = keccak256(
            abi.encodePacked(
                txType,
                user,
                timestamp,
                nonce,
                "DEFI_TX"
            )
        );
    }

    /**
     * @notice Encodes a stop-loss order.
     * @param user Order creator.
     * @param token Token to sell.
     * @param amount Amount to sell.
     * @param stopPrice Price at which the order triggers.
     * @param triggerPrice Execution price threshold.
     * @return stopLossData Packed encoding of the stop-loss order parameters.
     */
    function encodeStopLossOrder(
        address user,
        address token,
        uint256 amount,
        uint256 stopPrice,
        uint256 triggerPrice
    ) external pure returns (bytes memory stopLossData) {
        stopLossData = abi.encodePacked(
            user,
            token,
            amount,
            stopPrice,
            triggerPrice,
            "STOP_LOSS_ORDER"
        );
    }

    /**
     * @notice Encodes a take-profit order.
     * @param user Order creator.
     * @param token Token to sell.
     * @param amount Amount to sell.
     * @param takeProfitPrice Price at which the position is closed in profit.
     * @return takeProfitData Packed encoding of the take-profit order parameters.
     */
    function encodeTakeProfitOrder(
        address user,
        address token,
        uint256 amount,
        uint256 takeProfitPrice
    ) external pure returns (bytes memory takeProfitData) {
        takeProfitData = abi.encodePacked(
            user,
            token,
            amount,
            takeProfitPrice,
            "TAKE_PROFIT_ORDER"
        );
    }

    /**
     * @notice Encodes a trailing-stop order.
     * @param user Order creator.
     * @param token Token to sell.
     * @param amount Amount to sell.
     * @param trailingPercent Distance from the peak price that triggers the stop (basis points).
     * @param activationPrice Price at which trailing tracking begins.
     * @return trailingStopData Packed encoding of the trailing-stop order parameters.
     */
    function encodeTrailingStopOrder(
        address user,
        address token,
        uint256 amount,
        uint256 trailingPercent,
        uint256 activationPrice
    ) external pure returns (bytes memory trailingStopData) {
        trailingStopData = abi.encodePacked(
            user,
            token,
            amount,
            trailingPercent,
            activationPrice,
            "TRAILING_STOP_ORDER"
        );
    }

}
