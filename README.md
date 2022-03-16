trading bot using Balancer v2 custom pool

## 実装メモ

実装方針

- WeightedPoolをベースに、weightをストラテジーで変化させる
- weightが変化しても問題無いか、ConvergentCurvePoolとManagedPoolも参考にする

ストラテジー

- WBTC/USDC
- 平均足戦略を使う (売りはウェイト10:90で、買いは90:10)
- uniswap v3 oracleを使って近似計算 (オラクル攻撃に注意。多分過去データ使えば大丈夫)

重み変更 
weightが急激に変化すると取引コストが発生する (価格が急に乖離するので、アービトラージで資金を抜かれる)
ゆっくり変化させるとダッチオークションみたいになって多分コストが減る (ManagedPoolの実装)

ManagedPool updateWeightsGradually
重み変更が実装されている。
この中で、重み計算以外の処理をしていなければ、WeightedPoolベースの改造で問題無さそう。
_tokenStateとMiscDataは一つの変数にエンコードされてる(gas代減るの？)。
時刻に依存するコードを探せば良さそう
_calculateWeightChangeProgressで進捗が計算されている。
vaultを呼ぶ場所を探しても、重み計算関連はgetterからしか呼ばれていないから、
多分、WeightedPoolベースでgetterを書き換えれば、戦略実装できそう。

ManagedPoolとWeightedPoolはどちらもBaseWeightedPoolがベースだから、
WeightedPoolで実装されている関数を比較すれば理解できそう。

以下を実装すれば良い

- _getNormalizedWeight
- _getNormalizedWeights
- _getNormalizedWeightsAndMaxWeightIndex
- _getMaxTokens
- _getTotalTokens
- _scalingFactor
- _scalingFactors

_maxWeightTokenIndexは実装変える必要ある。
_getNormalizedWeightsAndMaxWeightIndexで返せば良い

重み合計はFixedPoint.ONE
https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/FixedPoint.sol
mulDownとかで掛け算できる

コードの変更が激しくてnpmのバージョンと合わない。
hardhatはsolcのremappingに対応していないから、
合うバージョン探した。

参考コード

- https://github.com/balancer-labs/balancer-v2-monorepo/tree/master/pkg/pool-weighted/contracts
- https://github.com/element-fi/elf-contracts/blob/main/contracts/ConvergentCurvePool.sol

uniswap v3 poolとbalancer vaultに依存するので、
mainet forkingでテストする。

```bash
npx hardhat node
npx hardhat test
```

uniswap v3 poolのoracleは古すぎると"OLD"でrevertされる。
24日前はダメだった。24時間くらいだと大丈夫だった

トークンの順番
トークンはアドレスでソートしないといけない (UNSORTED_ARRAY エラー)
https://dev.balancer.fi/resources/joins-and-exits/pool-joins

getPoolIdでpool id取得できる
https://etherscan.io/address/0x32296969ef14eb0c6d29669c550d4a0449130230/advanced#readContract

コントラクトのデプロイにガス代がかかる。
戦略部分だけ置き換えられるようにすると良いかも

joinKind
https://dev.balancer.fi/resources/joins-and-exits/pool-joins
↑に書かれているABIでエンコード

usdcは6 decimals
https://blog.coinbase.com/introduction-to-building-on-defi-with-ethereum-and-usdc-part-1-ea952295a6e2
https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48#readProxyContract

balancerのUIからデプロイしたプールを表示してみたら
poolTypeがundefinedでエラーになった。
コードを見るとpoolTypeはsolidityに直接的にあるものではないらしい。
balancer uiはthegraphでプール情報を取得している。
graphqlを直接叩いたら無かった。
https://api.thegraph.com/subgraphs/name/balancer-labs/balancer-polygon-v2/graphql

```text
query { 
  pools (
    first: 1000,
    where: {
      id: "0xcca8462288a499b695d2457c57730ec7efec700c0002000000000000000003d4"
    }
  ) {
      id 
      address
      poolType 
      swapFee
      tokensList
      totalLiquidity 
      totalSwapVolume
      totalSwapFee 
      totalShares
      owner 
      factory
      amp 
      createTime
      swapEnabled 
      tokens { 
        address
        balance
        weight
        priceRate
      }
    }
  }
```

vaultのPoolRegisteredイベントが出てるから、
知る機会はあるけど、ここからインデックスしてないのかも。
https://polygonscan.com/tx/0x8b7f0d2af82d333c8b98fd011bd7bc5956ee3e5dc2ec9b5505198f48485eb311#eventlog

balancer v2 subgraph
https://github.com/balancer-labs/balancer-subgraph-v2

ここにbalancer本家ではないプールが書いてある。
ここに追記しないとbalancer側で認識しないのかも。
https://github.com/balancer-labs/balancer-subgraph-v2/blob/master/src/mappings/poolFactory.ts#L16
ここでモデル作ってる
https://github.com/balancer-labs/balancer-subgraph-v2/blob/master/src/mappings/poolFactory.ts#L156

balancerのルーティングからは見れるのか？
https://dev.balancer.fi/resources/smart-order-router
https://github.com/balancer-labs/balancer-sor

balancer本家ではないプールが明記されている
https://github.com/balancer-labs/balancer-sor/blob/a604b621fa10136e8f84fa41d6f4382362d12fc5/tsconfig.json#L22
poolTypeが無いと扱えないかも
https://github.com/balancer-labs/balancer-sor/blob/master/src/pools/index.ts#L61
https://github.com/balancer-labs/balancer-sor/blob/a604b621fa10136e8f84fa41d6f4382362d12fc5/src/routeProposal/index.ts#L46

# AlphaSea

[AlphaSea](https://alphasea.io/) is a decentralized marketplace for market alpha.

This repository contains

- AlphaSea smart contract written in solidity
- AlphaSea subgraph definition

## Deployed contract

|Contract|Network|Address|
|:-:|:-:|:-:|
|Alphasea|Polygon mainnet|[0x9fD5e48d7Fb0c4a08d387EF87B17fe5861DB0506](https://polygonscan.com/address/0x9fD5e48d7Fb0c4a08d387EF87B17fe5861DB0506#code)|

## Development

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deploy.js
npx hardhat help
```

ローカルeth起動
```bash
npx hardhat node --hostname 0.0.0.0
```

コントラクトデプロイ
```bash
npx hardhat run --network localhost scripts/deploy.js
```

### test

```bash
npx hardhat coverage
```

### thegraph

```bash
cd subgraph
yarn install
npm run codegen
npm run build
```

```bash
ローカルethに対してローカルgraph-node起動
docker-compose up -d
```

ローカルgraph-nodeへsubgraphデプロイ
subgraph.yamlのdataSources[0].source.addressを、
デプロイしたコントラクトアドレスに書き換える。

```bash
npm run create-local
npm run deploy-local
```

thegraph hosted

- https://thegraph.com/hosted-service/subgraph/richmanbtc/alphasea-polygon
- https://thegraph.com/hosted-service/subgraph/richmanbtc/alphasea-mumbai

### testnet (ropsten)

ropsten用のgeth起動
peerを見つけるのに時間がかかる。

```bash
docker-compose -f docker-compose-ropsten.yml up -d
```

generate private key and address for ropsten
example: https://gist.github.com/miguelmota/3793b160992b4ea0b616497b8e5aee2f

deposit eth on faucet site

set ROPSTEN_PRIVATE_KEY env var
deploy contract to ropsten 

```bash
npx hardhat clean
npx hardhat compile
npx hardhat run --network ropsten scripts/deploy.js
```

deploy thegraph to thegraph.com (only richmanbtc can do)

subgraph/subgraph-ropsten.yaml内のdataSources[0].source.addressを、
デプロイしたコントラクトアドレスに書き換える。

```bash
cd subgraph
npm run codegen
npx graph auth --product hosted-service $THEGRAPH_COM_ACCESS_TOKEN
npm run deploy-ropsten
```

https://thegraph.com/hosted-service/subgraph/richmanbtc/alphasea-ropsten

以下のALPHASEA_CONTRACT_ADDRESSとALPHASEA_CONTRACT_ABIを書き換える。
ALPHASEA_CONTRACT_ABIは npm run print_abi で取得できる。

https://github.com/alphasea-dapp/alphasea-agent/blob/master/docker-compose-ropsten.yml

### testnet (mumbai)

set ROPSTEN_PRIVATE_KEY env var

```bash
npx hardhat clean
npx hardhat compile
npx hardhat run --network mumbai scripts/deploy.js
```

subgraph/subgraph-mumbai.yaml内のdataSources[0].source.addressを、
デプロイしたコントラクトアドレスに書き換える。

```bash
cd subgraph
npm run codegen
npx graph auth --product hosted-service $THEGRAPH_COM_ACCESS_TOKEN
npm run deploy-mumbai
```

### mainnet deploy (polygon)

set POLYGON_PRIVATE_KEY env var

```bash
export POLYGON_PRIVATE_KEY=$(cat /path/to/private_key)
```

```bash
npx hardhat clean
npx hardhat compile
npx hardhat run --network polygon scripts/deploy.js
```

subgraph/subgraph-polygon.yaml内のdataSources[0].source.addressを、
デプロイしたコントラクトアドレスに書き換える。

```bash
cd subgraph
npm run codegen
npx graph auth --product hosted-service $THEGRAPH_COM_ACCESS_TOKEN
npm run deploy-polygon
```

### verification (ropsten)

set env var ETHERSCAN_API_KEY

```bash
npx hardhat run --network ropsten scripts/verify.js
```

### verification (mumbai)

set env var POLYGONSCAN_API_KEY

```bash
npx hardhat run --network mumbai scripts/verify.js
```

### verification (polygon)

set env var POLYGONSCAN_API_KEY

```bash
npx hardhat run --network polygon scripts/verify.js
```

### security check

docker run -it -v $(pwd)/:/alphasea:ro trailofbits/eth-security-toolbox

docker run -it -v $(pwd)/:/alphasea:ro mythril/myth

### CI

github actionsでビルドを行っている。

設定: .github/workflows/build.yml

### Contract design

- Predictionは数が多いので、contractからreadしないものは、eventに書き込んでgas代を節約する
- gas代節約のために二重投稿は防がない。先を正とする
- predictionはaddressごとに同じキーで暗号化
- インターフェースはガス代節約重視で決める (一貫性が無い)
- 他コントラクトから全てのデータを検証できるようにgetterを作る (automatic getterで足りるものは作らない)
