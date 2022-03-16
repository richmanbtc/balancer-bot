
// kovan
// const vault = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
// const tokens = [
//     '0xd0a1e359811322d97991e03f863a0c30c2cf029c', // WETH
//     '0xdcfab8057d08634279f8201b55d311c2a67897d2', // USDC
// ]
// const uniswapV3Pool = '0x5502D6b59377906fe1C8888F74504A0EB753057f' // 適当なもの(テストなので)

// eth mainnet
const vault = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
const tokens = [
    '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', // USDC
    '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH
]
const uniswapV3Pool = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8' // WETH/USDC
const weth = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
const uniswapV3Router = '0xE592427A0AEce92De3Edee1F18E0157C05861564'

module.exports = {
    vault: vault,
    tokens: tokens,
    uniswapV3Pool: uniswapV3Pool,
    weth: weth,
    uniswapV3Router: uniswapV3Router,
}
