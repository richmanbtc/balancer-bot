// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../deps/balancer-v2-monorepo/pkg/pool-weighted/contracts/BaseWeightedPool.sol";

/**
 * @dev Basic Weighted Pool with immutable weights.
 */
abstract contract BaseBotPool is BaseWeightedPool {
    using FixedPoint for uint256;

    uint256 private constant _MAX_TOKENS = 2;

    uint256 private immutable _totalTokens;

    IERC20 internal immutable _token0;
    IERC20 internal immutable _token1;

    // All token balances are normalized to behave as if the token had 18 decimals. We assume a token's decimals will
    // not change throughout its lifetime, and store the corresponding scaling factor for each at construction time.
    // These factors are always greater than or equal to one: tokens with more than 18 decimals are not supported.

    uint256 internal immutable _scalingFactor0;
    uint256 internal immutable _scalingFactor1;

    uint256 public immutable _signalScale;

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
        uint256 minNormalizedWeight
    )
        BaseWeightedPool(
            vault,
            name,
            symbol,
            tokens,
            assetManagers,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        uint256 numTokens = tokens.length;
        InputHelpers.ensureInputLengthMatch(numTokens, 2);

        _totalTokens = numTokens;

        _require(minNormalizedWeight >= WeightedMath._MIN_WEIGHT, Errors.MIN_WEIGHT);
        _require(FixedPoint.ONE / 2 > minNormalizedWeight, Errors.MIN_WEIGHT);
        _signalScale = (FixedPoint.ONE / 2 - minNormalizedWeight) / 128;

        // Immutable variables cannot be initialized inside an if statement, so we must do conditional assignments
        _token0 = tokens[0];
        _token1 = tokens[1];

        _scalingFactor0 = _computeScalingFactor(tokens[0]);
        _scalingFactor1 = _computeScalingFactor(tokens[1]);
    }

    function _getNormalizedWeight0(int8 signal) private view returns (uint256) {
        return FixedPoint.ONE / 2 + uint256(int256(_signalScale) * int256(signal));
    }

    function _getNormalizedWeight1(int256 signal) private view returns (uint256) {
        return FixedPoint.ONE / 2 - uint256(int256(_signalScale) * int256(signal));
    }

    function _getNormalizedWeight(IERC20 token) internal view virtual override returns (uint256) {
        // prettier-ignore
        int8 signal = getSignal();
        if (token == _token0) { return _getNormalizedWeight0(signal); }
        else if (token == _token1) { return _getNormalizedWeight1(signal); }
        else {
            _revert(Errors.INVALID_TOKEN);
            return 0;
        }
    }

    function _getNormalizedWeights() internal view virtual override returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory normalizedWeights = new uint256[](totalTokens);

        int8 signal = getSignal();
        // prettier-ignore
        {
            normalizedWeights[0] = _getNormalizedWeight0(signal);
            normalizedWeights[1] = _getNormalizedWeight1(signal);
        }

        return normalizedWeights;
    }

    function _getNormalizedWeightsAndMaxWeightIndex()
        internal
        view
        virtual
        override
        returns (uint256[] memory, uint256)
    {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory normalizedWeights = new uint256[](totalTokens);

        int8 signal = getSignal();
        {
            normalizedWeights[0] = _getNormalizedWeight0(signal);
            normalizedWeights[1] = _getNormalizedWeight1(signal);
        }

        return (normalizedWeights, signal > 0 ? 0 : 1);
    }

    function _getMaxTokens() internal pure virtual override returns (uint256) {
        return _MAX_TOKENS;
    }

    function _getTotalTokens() internal view virtual override returns (uint256) {
        return _totalTokens;
    }

    /**
     * @dev Returns the scaling factor for one of the Pool's tokens. Reverts if `token` is not a token registered by the
     * Pool.
     */
    function _scalingFactor(IERC20 token) internal view virtual override returns (uint256) {
        // prettier-ignore
        if (token == _token0) { return _scalingFactor0; }
        else if (token == _token1) { return _scalingFactor1; }
        else {
            _revert(Errors.INVALID_TOKEN);
            return 0;
        }
    }

    function _scalingFactors() internal view virtual override returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory scalingFactors = new uint256[](totalTokens);

        // prettier-ignore
        {
            scalingFactors[0] = _scalingFactor0;
            scalingFactors[1] = _scalingFactor1;
        }

        return scalingFactors;
    }

    // Strategy methods

    function getSignal() public view virtual returns (int8);
}
