// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "src/AbiEncoderDemo.sol";


contract TestAbiEncoderDemo is Test {

    AbiEncoderDemo private encoder;

    function setUp() public {
        encoder = new AbiEncoderDemo();
    }

    // ── createPoolIdentifier ──────────────────────────────────────────────────

    function testPoolIdentifierIsOrderIndependent() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);

        bytes32 poolIdAB = encoder.createPoolIdentifier(tokenA, tokenB, 0);
        bytes32 poolIdBA = encoder.createPoolIdentifier(tokenB, tokenA, 0);

        assertEq(poolIdAB, poolIdBA);
    }

    function testDifferentFeesProduceDifferentPoolIdentifiers() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);

        bytes32 poolIdLow  = encoder.createPoolIdentifier(tokenA, tokenB, 500);
        bytes32 poolIdHigh = encoder.createPoolIdentifier(tokenA, tokenB, 3000);

        assertNotEq(poolIdLow, poolIdHigh);
    }

    // ── encodeTradingPosition ─────────────────────────────────────────────────

    function testEncodeTradingPositionMatchesExpected() public view {
        address user       = address(0x1000);
        address tokenIn    = address(0x0001);
        address tokenOut   = address(0x0002);
        uint256 amountIn   = 1e18;
        uint256 minOut     = 2e18;
        uint256 deadline   = 1_800_000_000;

        bytes memory expected = abi.encodePacked(user, tokenIn, tokenOut, amountIn, minOut, deadline);
        bytes32 expectedId    = keccak256(expected);

        (bytes32 positionId, bytes memory encodedData) = encoder.encodeTradingPosition(
            user, tokenIn, tokenOut, amountIn, minOut, deadline
        );

        assertEq(encodedData, expected);
        assertEq(positionId, expectedId);
    }

    // ── encodeSwapData ────────────────────────────────────────────────────────

    function testEncodeSwapDataRevertsOnMismatchedArrayLengths() public {
        address[] memory path   = new address[](1);
        path[0] = address(0x1);
        uint256[] memory amount = new uint256[](2);
        amount[0] = 10;
        amount[1] = 20;

        vm.expectRevert("Arrays must have the same size");
        encoder.encodeSwapData(path, amount, 1_800_000_000);
    }

    function testEncodeSwapDataMatchesExpected() public view {
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
        for (uint i = 0; i < path.length; i++) {
            pathData = abi.encodePacked(pathData, path[i]);
        }
        bytes memory amountData;
        for (uint i = 0; i < amount.length; i++) {
            amountData = abi.encodePacked(amountData, amount[i]);
        }
        bytes memory expected = abi.encodePacked(pathData, amountData, deadline);

        assertEq(encoder.encodeSwapData(path, amount, deadline), expected);
    }

    // ── encodeLimitOrder ──────────────────────────────────────────────────────

    function testEncodeLimitOrderMatchesExpected() public view {
        address maker    = address(0xA1);
        address taker    = address(0xA2);
        address tokenIn  = address(0xB1);
        address tokenOut = address(0xB2);
        uint256 amountIn  = 1e18;
        uint256 amountOut = 2e18;
        uint256 nonce     = 42;

        bytes memory expected = abi.encodePacked(
            maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce, "ORDER_DATA_V1"
        );
        bytes32 expectedHash = keccak256(expected);

        (bytes32 orderHash, bytes memory orderData) = encoder.encodeLimitOrder(
            maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce
        );

        assertEq(orderData, expected);
        assertEq(orderHash, expectedHash);
    }

    // ── encodeYieldPosition ───────────────────────────────────────────────────

    function testEncodeYieldPositionMatchesExpected() public view {
        address user      = address(0xC1);
        bytes32 poolId    = keccak256("pool");
        uint256 amount    = 500e18;
        uint256 startTime = 1_700_000_000;

        bytes32 expected = keccak256(abi.encodePacked(user, poolId, amount, startTime, "YIELD_POSITION"));

        assertEq(encoder.encodeYieldPosition(user, poolId, amount, startTime), expected);
    }

    // ── encodeFlashLoan ───────────────────────────────────────────────────────

    function testEncodeFlashLoanMatchesExpected() public view {
        address token       = address(0xD1);
        uint256 amount      = 1_000e18;
        bytes memory cbData = hex"deadbeef";

        bytes memory expected = abi.encodePacked(token, amount, cbData, "FLASH_LOAN_V1");

        assertEq(encoder.encodeFlashLoan(token, amount, cbData), expected);
    }

    // ── encodeStakingPoolConfig ───────────────────────────────────────────────

    function testEncodeStakingPoolConfigMatchesExpected() public view {
        address token       = address(0xE1);
        uint256 rewardRate  = 100;
        uint256 lockPeriod  = 30 days;
        uint256 maxStakers  = 1000;

        bytes memory expected = abi.encodePacked(
            token, rewardRate, lockPeriod, maxStakers, block.timestamp
        );

        assertEq(encoder.encodeStakingPoolConfig(token, rewardRate, lockPeriod, maxStakers), expected);
    }

    // ── createUserMultiPoolHash ───────────────────────────────────────────────

    function testCreateUserMultiPoolHashMatchesExpected() public view {
        address user = address(0xF1);
        bytes32[] memory poolIds = new bytes32[](2);
        poolIds[0] = keccak256("poolA");
        poolIds[1] = keccak256("poolB");

        bytes memory data = abi.encodePacked(user, poolIds[0], poolIds[1], "MULTI_POOL_USER");
        bytes32 expected  = keccak256(data);

        assertEq(encoder.createUserMultiPoolHash(user, poolIds), expected);
    }

    function testCreateUserMultiPoolHashEmptyPools() public view {
        address user = address(0xF2);
        bytes32[] memory poolIds = new bytes32[](0);

        bytes32 expected = keccak256(abi.encodePacked(user, "MULTI_POOL_USER"));

        assertEq(encoder.createUserMultiPoolHash(user, poolIds), expected);
    }

    // ── encodeYieldStrategy ───────────────────────────────────────────────────

    function testEncodeYieldStrategyRevertsOnMismatchedArrayLengths() public {
        address[] memory pools = new address[](2);
        pools[0] = address(0x1);
        pools[1] = address(0x2);
        uint256[] memory weighs = new uint256[](1);
        weighs[0] = 50;

        vm.expectRevert("Array length must be equal");
        encoder.encodeYieldStrategy("StrategyA", pools, weighs);
    }

    function testEncodeYieldStrategyMatchesExpected() public view {
        string memory name = "StrategyA";
        address[] memory pools = new address[](2);
        pools[0] = address(0x1);
        pools[1] = address(0x2);
        uint256[] memory weighs = new uint256[](2);
        weighs[0] = 60;
        weighs[1] = 40;

        bytes memory nameData   = abi.encodePacked(name);
        bytes memory poolsData  = abi.encodePacked(pools[0], pools[1]);
        bytes memory weighsData = abi.encodePacked(weighs[0], weighs[1]);
        bytes memory expected   = abi.encodePacked(nameData, poolsData, weighsData, "YIELD_STRATEGY_V1");

        assertEq(encoder.encodeYieldStrategy(name, pools, weighs), expected);
    }

    // ── encodeCrossChainBridgeData ────────────────────────────────────────────

    function testEncodeCrossChainBridgeDataMatchesExpected() public view {
        uint256 src       = 1;
        uint256 dst       = 42161;
        address token     = address(0x11);
        uint256 amount    = 10e18;
        address recipient = address(0x22);

        bytes memory expected = abi.encodePacked(src, dst, token, amount, recipient, "CROSS_CHAIN_BRIDGE");

        assertEq(encoder.encodeCrossChainBridgeData(src, dst, token, amount, recipient), expected);
    }

    // ── createDeFiTransactionId ───────────────────────────────────────────────

    function testCreateDeFiTransactionIdMatchesExpected() public view {
        string memory txType = "SWAP";
        address user         = address(0x33);
        uint256 timestamp    = 1_800_000_000;
        uint256 nonce        = 7;

        bytes32 expected = keccak256(abi.encodePacked(txType, user, timestamp, nonce, "DEFI_TX"));

        assertEq(encoder.createDeFiTransactionId(txType, user, timestamp, nonce), expected);
    }

    // ── encodeStopLossOrder ───────────────────────────────────────────────────

    function testEncodeStopLossOrderMatchesExpected() public view {
        address user         = address(0x44);
        address token        = address(0x55);
        uint256 amount       = 100e18;
        uint256 stopPrice    = 1800e18;
        uint256 triggerPrice = 1750e18;

        bytes memory expected = abi.encodePacked(
            user, token, amount, stopPrice, triggerPrice, "STOP_LOSS_ORDER"
        );

        assertEq(encoder.encodeStopLossOrder(user, token, amount, stopPrice, triggerPrice), expected);
    }

    // ── encodeTakeProfitOrder ─────────────────────────────────────────────────

    function testEncodeTakeProfitOrderMatchesExpected() public view {
        address user            = address(0x66);
        address token           = address(0x77);
        uint256 amount          = 50e18;
        uint256 takeProfitPrice = 2200e18;

        bytes memory expected = abi.encodePacked(
            user, token, amount, takeProfitPrice, "TAKE_PROFIT_ORDER"
        );

        assertEq(encoder.encodeTakeProfitOrder(user, token, amount, takeProfitPrice), expected);
    }

    // ── encodeTrailingStopOrder ───────────────────────────────────────────────

    function testEncodeTrailingStopOrderMatchesExpected() public view {
        address user            = address(0x88);
        address token           = address(0x99);
        uint256 amount          = 75e18;
        uint256 trailingPercent = 500;    // 5%
        uint256 activationPrice = 2100e18;

        bytes memory expected = abi.encodePacked(
            user, token, amount, trailingPercent, activationPrice, "TRAILING_STOP_ORDER"
        );

        assertEq(encoder.encodeTrailingStopOrder(user, token, amount, trailingPercent, activationPrice), expected);
    }

}
