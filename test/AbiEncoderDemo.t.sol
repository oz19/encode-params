// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "src/AbiEncoderDemo.sol";


/// @title TestAbiEncoderDemo
/// @notice Tests for `AbiEncoderDemo.sol`
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

        assertEq(poolIdAB, poolIdBA, "Tokens are not correctly sorted");
    }

    function testDifferentFeesCreateDifferentPoolIdentifier() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);
        uint24 feeA = 3000;
        uint24 feeB = 500;

        bytes32 poolIdWithFeeA = encoder.createPoolIdentifier(tokenA, tokenB, feeA);
        bytes32 poolIdWithFeeB = encoder.createPoolIdentifier(tokenA, tokenB, feeB);

        assertNotEq(poolIdWithFeeA, poolIdWithFeeB, "Changing fee doesn't create a different `poolId`");
    }

    function testEncodeTradingPositionWorksCorrectly() public view {
        address user = address(0x1000);
        address tokenIn = address(0x0001);
        address tokenOut = address(0x0002);
        uint256 amountIn = 1e18;
        uint256 minAmountOut = 2e18;
        uint256 deadline = 1_800_000_000;  // Timestamp format
        bytes memory encodedDataExpected = abi.encodePacked(
            user,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            deadline
        );
        bytes32 positionIdExpected = keccak256(encodedDataExpected);

        (bytes32 positionId, bytes memory encodedData) = encoder.encodeTradingPosition(
            user,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            deadline
        );

        assertEq(encodedData, encodedDataExpected, "Data was not correctly encoded");
        assertEq(positionId, positionIdExpected, "keccak did not work correctly");
    }

    function testEncodeSwapDataShouldFailForDifferentPathAndAmountArraySized() public {
        address[] memory path = new address[](1);
        path[0] = address(0x1);
        uint256[] memory amount = new uint256[](2);
        amount[0] = 10;
        amount[1] = 20;
        uint256 deadline = 1_800_000_000;

        vm.expectRevert("Arrays must have the same size");
        encoder.encodeSwapData(path, amount, deadline);
    }
    
    function testEncodeSwapDataWorksCorrectly() public view {
        address[] memory path = new address[](3);
        path[0] = address(0x1);
        path[1] = address(0x2);
        path[2] = address(0x3);
        uint256[] memory amount = new uint256[](3);
        amount[0] = 10;
        amount[1] = 20;
        amount[2] = 30;
        uint256 deadline = 1_800_000_000;
        bytes memory pathData;
        for(uint i = 0; i < path.length; i++) {
            pathData = abi.encodePacked(pathData, path[i]);
        }
        bytes memory amountData;
        for(uint i = 0; i < amount.length; i++) {
            amountData = abi.encodePacked(amountData, amount[i]);
        }
        bytes memory swapDataExpected = abi.encodePacked(pathData, amountData, deadline);

        bytes memory swapData = encoder.encodeSwapData(path, amount, deadline);

        assertEq(swapData, swapDataExpected, "Swap Data should be equal and it's not");
    }

}