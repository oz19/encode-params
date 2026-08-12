// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/**
* @title ABI Encoder Demo
* @author Gurutz Ocon
* @dev This smart contract shows different uses of `abi.encodePacked` in DeFi protocols.
*/
contract AbiEncoderDemo {

    // Events to show the codification
    event DataEncoded(bytes32 indexed hash, bytes encodedData);
    event PoolIdentifierCreated(bytes32 indexed poolId, address token, uint256 rate);
    event UserPositionCreated(bytes32 indexed positionId, address user, uint256 amount);

    /**
    * @dev this function encodes the pool parameters
    * @param tokenA first pool token
    * @param tokenB second pool token
    * @param fee pool fee
    * @return poolId identifer (unique for this pool)
    */
    function createPoolIdentifier(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns(bytes32 poolId) {
        // Token order matters for encoding. Our criteria is lowest token address first (token0).
        (address token0, address token1) = (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);

        // Use of `abi.encodePacked`: Create a unique Pool Identifier
        poolId = keccak256(abi.encodePacked(token0, token1, fee));
    }

    /**
    * @dev encode trading position ID and its own data
    * @param user user creating the position
    * @param tokenIn token used to buy the token
    * @param tokenOut token bought
    * @param amountIn amount used to open the position
    * @param minAmountOut the minimum amount accepted back
    * @param deadline max timestamp to run the transaction
    * @return positionId 
    * @return encodedData
    */
    function encodeTradingPosition(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external pure returns(bytes32 positionId, bytes memory encodedData) {
        // Encode the position data
        encodedData = abi.encodePacked(user, tokenIn, tokenOut, amountIn, minAmountOut, deadline);

        // Create a unique position ID
        positionId = keccak256(encodedData);
    }

    /**
    * @dev Swap data used in a DEX
    * @param path array of tokens for the swap
    * @param amount array of amounts
    * @param deadline max timestamp to run the transaction
    * @return swapData
    */
    function encodeSwapData(
        address[] calldata path,
        uint256[] calldata amount,
        uint256 deadline
    ) external pure returns(bytes memory swapData) {
        require(path.length == amount.length, "Arrays must have the same size");

        // Encode path data
        bytes memory pathData;
        for (uint i = 0; i < path.length; i++) {
            pathData = abi.encodePacked(pathData, path[i]);
        }

        // Encode amount data
        bytes memory amountData;
        for (uint i = 0; i < amount.length; i++) {
            amountData = abi.encodePacked(amountData, amount[i]);
        }

        // Encode everything
        swapData = abi.encodePacked(pathData, amountData, deadline);
    }

    /**
    * @dev Encode limit orders
    * @param maker Maker address
    * @param taker Taker address
    * @param tokenIn Input token
    * @param tokenOut Output token
    * @param amountIn Input amount
    * @param amountOut Output amount
    * @param nonce Unique nonce
    * @return orderHash
    * @return orderData
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
        // Encode order data
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

        // Create order hash
        orderHash = keccak256(orderData);
    }

    /**
    * @dev Encodes data for a yield farming position
    * @param user User address
    * @param poolId Pool Identifier
    * @param amount Staked amount
    * @param startTime Start time
    * @return positionId
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
    * @dev Encodes data for a flash loan
    * @param token Flash loan token
    * @param amount Flash loan amount
    * @param callbackData Callback data
    * @return flashLoanData
    */
    function encodeFlashLoan(
        address token,
        uint256 amount,
        bytes calldata callbackData
    ) external pure returns(bytes memory flashLoanData) {
        flashLoanData = abi.encodePacked(token, amount, callbackData, "FLASH_LOAN_V1");
    }

    /**
    * @dev Encodes parameters for a staking pool
    * @param token Token address
    * @param rewardRate Reward rate
    * @param lockPeriod Lock period
    * @param maxStakers Maximum number of stakers
    * @return poolConfig
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

    function encodeYieldStrategy(
        string calldata strategyName,
        address[] calldata pools,
        uint256[] calldata weighs
    ) external pure returns(bytes memory strategyData) {
        require(pools.length == weighs.length, "Array length must be equal");

        // Encode strategy name
        bytes memory nameData = abi.encodePacked(strategyName);

        // Encode pools data
        bytes memory poolsData;
        for (uint i = 0; i < pools.length; i++ ) {
            poolsData = abi.encodePacked(poolsData, pools[i]);
        }

        // Encode weighs data
        bytes memory weighsData;
        for (uint i = 0; i < weighs.length; i++) {
            weighsData = abi.encodePacked(weighsData, weighs[i]);
        }

        strategyData = abi.encodePacked(nameData, poolsData, weighsData, "YIELD_STRATEGY_V1");
    }

    /**
     * @dev Demonstrates encoding data for a cross-chain bridge
     * @param sourceChain Source chain
     * @param targetChain Target chain
     * @param token Token to transfer
     * @param amount Amount
     * @param recipient Recipient
     * @return bridgeData Encoded bridge data
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
     * @dev Creates a unique identifier for a DeFi transaction
     * @param txType Transaction type
     * @param user User
     * @param timestamp Timestamp
     * @param nonce Unique nonce
     * @return txId Unique transaction identifier
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
     * @dev Encodes data for a stop loss order
     * @param user User address
     * @param token Token to sell
     * @param amount Amount to sell
     * @param stopPrice Stop loss price
     * @param triggerPrice Trigger price
     * @return stopLossData Encoded order data
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
     * @dev Encodes data for a take profit order
     * @param user User address
     * @param token Token to sell
     * @param amount Amount to sell
     * @param takeProfitPrice Take profit price
     * @return takeProfitData Encoded order data
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
     * @dev Encodes data for a trailing stop order
     * @param user User address
     * @param token Token to sell
     * @param amount Amount to sell
     * @param trailingPercent Trailing percentage
     * @param activationPrice Activation price
     * @return trailingStopData Encoded order data
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