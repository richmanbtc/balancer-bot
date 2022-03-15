pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseBotPool.sol";
import "../deps/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract BotPool is BaseBotPool {
    IUniswapV3Pool private _uniswapV3Pool;

    constructor(
        IVault vault,
        IERC20[] memory tokens,
        IUniswapV3Pool uniswapV3Pool
    )
    BaseBotPool(
        vault,
        "BotPool",
        "BOTPOOL",
        tokens,
        new address[](2), // assetManagers zero address means no asset manager
        1e15, // swapFeePercentage 1e16 == 1%
        // https://dev.balancer.fi/guides/guided-tour-of-balancer-vault/episode-3-deploying-a-pool
        0, // pauseWindowDuration
        0, // bufferPeriodDuration
        msg.sender,
        FixedPoint.ONE * 10 / 100
    )
    {
        _uniswapV3Pool = uniswapV3Pool;
    }

    function getSignal() public view virtual override returns (int8) {
        // https://docs.uniswap.org/protocol/reference/core/UniswapV3Pool#observe
        uint32[] memory secondsAgos = new uint32[](25);
        for (uint32 i = 0; i < secondsAgos.length; i++) {
            secondsAgos[secondsAgos.length - 1 - i] = 60 * 60 * i + 60;
        }

        // https://docs.uniswap.org/protocol/concepts/V3-overview/oracle
        int64[] memory ticks = new int64[](secondsAgos.length - 1);
        (int56[] memory tickCumulatives, ) = _uniswapV3Pool.observe(secondsAgos);

        for (uint i = 0; i < ticks.length; i++) {
            ticks[i] = (tickCumulatives[i + 1] - tickCumulatives[i]) / (secondsAgos[i] - secondsAgos[i + 1]);
        }

        int rsi = 0;
        for (uint i = 0; i < ticks.length - 1; i++) {
            rsi += ticks[i] < ticks[i + 1] ? int(1) : -1;
        }

        return int8(127 * rsi / int(ticks.length - 1));
    }
}
