const { expect } = require("chai");
const { ethers } = require("hardhat");
const config = require('../scripts/config')
const hre = require("hardhat");

const BigNumber = (x) => {
    return hre.ethers.BigNumber.from(x)
};

describe("integraion", function () {
    before(async function () {
        this.BotPool = await ethers.getContractFactory('BotPool');
    });

    beforeEach(async function () {
        const addresses = await ethers.getSigners()
        this.myAddress = addresses[0]
        this.otherAddress = addresses[1]

        const pool = await this.BotPool.deploy(
            config.vault,
            config.tokens,
            config.uniswapV3Pool,
        );
        await pool.deployed();
        this.pool = pool;
    });

    describe("join,swap,exit", function () {
        it("ok", async function () {

            // prepare tokens using uniswap

            const weth = await hre.ethers.getContractAt(
                "IWETH",
                config.weth
            );
            await (await weth.deposit(
                {
                    value: hre.ethers.utils.parseEther('10'),
                }
            )).wait()

            const uniswapV3Router = await hre.ethers.getContractAt(
                "ISwapRouter",
                config.uniswapV3Router
            );
            await (await weth.approve(
                config.uniswapV3Router,
                hre.ethers.utils.parseEther('100'),
            )).wait()
            await (await uniswapV3Router.exactInputSingle(
                {
                    tokenIn: config.weth,
                    tokenOut: config.tokens[0],
                    fee: 3000, // https://etherscan.io/address/0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8#readContract
                    recipient: this.myAddress.address,
                    deadline: 2000000000,
                    amountIn: hre.ethers.utils.parseEther('5'),
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: 0,
                }
            )).wait()

            console.log('exactInputSingle finished')

            const vault = await hre.ethers.getContractAt(
                "IVault",
                config.vault
            );

            const usdc = await hre.ethers.getContractAt(
                "IERC20",
                config.tokens[0]
            );
            await (await usdc.approve(
                config.vault,
                hre.ethers.utils.parseEther('10000000'),
            )).wait()

            await (await weth.approve(
                config.vault,
                hre.ethers.utils.parseEther('10000000'),
            )).wait()

            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

            const poolId = await this.pool.getPoolId()
            const userData = hre.ethers.utils.defaultAbiCoder.encode(
                ['uint', 'uint[]'],
                [
                    0, // JoinKind.INIT
                    [
                        '' + 100000 * 1000,
                        hre.ethers.utils.parseEther('1')
                    ]
                ]
            )
            await (await vault.joinPool(
                poolId,
                this.myAddress.address,
                this.myAddress.address,
                {
                    assets: config.tokens,
                    maxAmountsIn: [
                        '' + 100000 * 1000, // USDC
                        hre.ethers.utils.parseEther('1') // WETH
                    ],
                    userData: userData,
                    fromInternalBalance: false,
                },
                { value: 0 }
            )).wait()

            console.log('joinPool finished')
            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

            const swapStruct = {
                poolId: poolId,
                kind: 0, // GIVEN_IN
                assetIn: config.tokens[0],
                assetOut: config.tokens[1],
                amount: 100000 * 100,
                userData: '0x'
            };

            const fundStruct = {
                sender: this.myAddress.address,
                recipient: this.myAddress.address,
                fromInternalBalance: false,
                toInternalBalance: false
            };

            await (await vault.swap(
                swapStruct,
                fundStruct,
                BigNumber('20000000000000'),
                BigNumber('2000000000'),
            )).wait()

            console.log('swap finished')
            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

            const EXACT_BPT_IN_FOR_TOKENS_OUT = 1;

            const userDataExit = hre.ethers.utils.defaultAbiCoder.encode(
                ['uint', 'uint'],
                [
                    EXACT_BPT_IN_FOR_TOKENS_OUT,
                    (await this.pool.balanceOf(this.myAddress.address)),
                ]
            )

            await (await vault.exitPool(
                poolId,
                this.myAddress.address,
                this.myAddress.address,
                {
                    assets: config.tokens,
                    minAmountsOut: [
                        0,
                        0,
                    ],
                    userData: userDataExit,
                    toInternalBalance: false,
                },
                { value: 0 }
            )).wait()

            console.log('exitPool finished')
            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

        });
    })
})
