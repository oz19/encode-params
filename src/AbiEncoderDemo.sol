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
}