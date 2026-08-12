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
            "RANDOM_STRING_ORDER_DATA_V1"
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
        positionId = keccak256(abi.encodePacked(user, poolId, amount, startTime, "RANDOM_STRING_YIELD_POSITION");)
    }
}