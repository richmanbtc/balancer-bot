const { expect } = require("chai");
const { ethers } = require("hardhat");
const config = require('../scripts/config')
const hre = require("hardhat");

const daySeconds = 24 * 60 * 60

describe("getSignal", function () {
    before(async function () {
        this.BotPool = await ethers.getContractFactory('BotPool');
    });

    beforeEach(async function () {
        const pool = await this.BotPool.deploy(
            config.vault,
            config.tokens,
            config.uniswapV3Pool,
        );
        await pool.deployed();
        this.pool = pool;
    });

    describe("getSignal", function () {
        it("ok", async function () {
            const result = await this.pool.getSignal()
            expect(result).to.equal(0)
        });
    })
})
