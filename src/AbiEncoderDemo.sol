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
    ) external pure returns(bytes32) {
        // Token order matters for encoding. Our criteria is lowest token address first (token0).
        (address token0, address token1) = (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);

        // Use of `abi.encodePacked`: Create a unique Pool Identifier
        bytes32 poolId = keccak256(abi.encodePacked(token0, token1, fee));
        return poolId
    }

}