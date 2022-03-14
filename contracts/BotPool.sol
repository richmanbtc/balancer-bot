pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseBotPool.sol";
import "../deps/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract BotPool is BaseBotPool {
    IUniswapV3Pool private _uniswapV3Pool;

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        address[] memory assetManagers,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner,
        IUniswapV3Pool uniswapV3Pool
    )
    BaseBotPool(
        vault,
        name,
        symbol,
        tokens,
        assetManagers,
        swapFeePercentage,
        pauseWindowDuration,
        bufferPeriodDuration,
        owner,
        FixedPoint.ONE * 10 / 100
    )
    {
        _uniswapV3Pool = uniswapV3Pool;
    }

    function getSignal() public view virtual override returns (int8) {
        // https://docs.uniswap.org/protocol/reference/core/UniswapV3Pool#observe
        uint32[] memory secondsAgos = new uint32[](25);
        for (uint32 i = 0; i < secondsAgos.length; i++) {
            secondsAgos[secondsAgos.length - 1 - i] = 24 * 60 * 60 * i + 60;
        }

        int64[] memory twaps = new int64[](secondsAgos.length - 1);
        (int56[] memory tickCumulatives, ) = _uniswapV3Pool.observe(secondsAgos);

        for (uint i = 0; i < twaps.length; i++) {
            twaps[i] = (tickCumulatives[i + 1] - tickCumulatives[i]) / (secondsAgos[i + 1] - secondsAgos[i]);
        }

        int rsi = 0;
        for (uint i = 0; i < twaps.length - 1; i++) {
            rsi += twaps[i] < twaps[i + 1] ? int(1) : -1;
        }

        return int8(127 * rsi / int(twaps.length - 1));
    }
}
