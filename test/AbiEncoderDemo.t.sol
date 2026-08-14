// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "src/AbiEncoderDemo.sol";


/// @title TestAbiEncoderDemo
/// @notice Tests targeting 100% coverage for `AbiEncoderDemo.sol`
contract TestAbiEncoderDemo is Test {

    AbiEncoderDemo private encoder;

    /// @dev deploy a fresh encoder for each test
    function setUp() public {
        encoder = new AbiEncoderDemo();
    }

    /// @dev poolId must be invariant to token sorting (tokens are sorted internally)
    function testTokensAreSortedCorrectlyWhileCreatingPoolIdentifier() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);

        bytes32 poolIdAB = encoder.createPoolIdentifier(tokenA, tokenB, 0);
        bytes32 poolIdBA = encoder.createPoolIdentifier(tokenB, tokenA, 0);

        assertEq(poolIdAB, poolIdBA);
    }

}