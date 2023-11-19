# SUClave:

**DEFI is broken**

- Nobody could have imagined that a single algorithm (x*y=k) would lead to the creation of a $60 billion market. UNI V2 has opened up a new world in blockchain technology, known as DeFi, but this world is not without its problem and needs fixing. Let's dive into the problem and explore our proposed solution for it.

---

**Why AMM’s are Dumb**

- Let's break down the issue step by step. In Automated Market Makers (AMMs), there are two main players: Liquidity Providers (LPs) and Traders. LPs earn fees because Traders are willing to pay these fees.
![doganalpaslan333333333](https://github.com/getclave/suclave-ethglobal-istanbul/assets/71966179/810f3534-4177-4b20-bc91-e007b366a830)




AMMs are designed to protect Liquidity Providers (LPs) from Impermanent Loss (IL) in scenarios where there's no price volatility. What does this mean?

Imagine a pool where LPs have supplied 1 ETH and 1000 USDC. If the price remains unchanged after a month, these LPs can retrieve their funds without incurring any loss which is good but there is a problem. During the month, the price of ETH could surge to 4000 USDC and then drop back to 1000 USDC. This kind of volatility benefits primarily arbitrage bots, as AMMs are unable to see what’s going on outside of the blockchains and therefore cannot change their LP fees accordingly in response to such fluctuations. In this situation, it's the arbitrage bots that are profiting. While regular users remain unaffected, the ones who end up losing money are the Liquidity Providers (LPs). Traders, as well as bots, have the opportunity to profit from market volatility. Similarly, Liquidity Providers (LPs) should also have a mechanism to offset the effects of volatility and make money. But the question is, how can LP’s achieve profitability?


![dogan123123213](https://github.com/getclave/suclave-ethglobal-istanbul/assets/71966179/d33df954-c7bc-40db-8fad-3bc9f41ecd29)


**SUAVE and UNI V4:** 

SUAVE is a credible off-chain computation platform designed to democratize block building. Developers can perform complex computations and execute smart contracts on it. Additionally, users have the ability to relay their arbitrary data to other blockchains. 
UNI V4 is Uniswap’s newest upgrade for their protocol. It allows developers to build custom conditions, functions and novel applications on the top of Uniswap’s Liquidity pools permissionlessly. UNIswAP v4 allows anyone to deploy new concentrated liquidity pools with custom functionality. For each pool, the creator can define a "hook contract" that implements logic executed at key points in a call's lifecycle. These hooks can also manage the swap fee of the pool, as well as withdrawal fees charged to liquidity providers. 
**SUClave: A New AMM Design Using SUAVE and Uniswap V4**
Arbitrage bots are doing MEV attacks through the Tap of Pool, aiming to be the first to access the liquidity pool. Being the first one that touches the pool gives an opportunity for MEV. While arbitrage is a common aspect of finance, the issue here is that Liquidity Providers (LPs) are missing out on potential profits. Essentially, these bots are earning profits using the funds provided by LPs, who are unable to capitalize on these opportunities themselves. For instance, consider a situation where the actual market price of ETH rises to $2000, but within the pool, it's still valued at $1000. In such cases, LPs could have profited by trading their ETH for USDC. However, it's the bots that are seizing these opportunities instead. Therefore, if there were a method to redistribute the profits made from arbitrage back to the LPs, it could effectively address this problem.

In SUAVE, various auction mechanisms allow bids to be placed freely, and developers are provided with an attestation signature by SUAVE. This signature serves as proof that a transaction originated from one of these auctions. Consequently, it becomes straightforward to implement an auction mechanism that can also be authenticated on the Ethereum network. To leverage this capability, we've integrated this auction approach with a custom UNI V4 Hook. This specific hook is designed to only accept transactions that are verified as coming from a SUAVE auction. How is it works?

Firstly user sends an intent + signature, then the signature is being verified and passes through the auction. The auction is a free market and the one who gives more money to LP’s wins the auction. Then transaction is sending to the Ethereum with an attestation. Hook firstly checks if the attestation valid or not, then executes the transaction. 

![Doganabsesnssnsnsnsns](https://github.com/getclave/suclave-ethglobal-istanbul/assets/71966179/fcaf32fa-b1d2-41b0-a0e6-5cc20532ab89)


**Two Different Attestation Mechanism That Enables to Use the Hook:** 

Having the first access to the pool offers a significant advantage, but our aim is to enable multiple transactions to interact with hooks within a block. To achieve this, we've designed two distinct mechanisms. The first is an auction system that determines who gets to be the initial toucher of the pool. This position holds the greatest benefit for executing arbitrages, with the auction bid being directly allocated to the LP reward contract. The second mechanism is a backrunning system, akin to the MEV Share SUAPP. In this setup, another participant backruns the transactions of users, distributing a portion of the proceeds to both the users and the Liquidity Providers.

**Game Theory:** 

While MEV typically has negative effects, it's important to explore options for a "benign" form of MEV. SUClave serves as an example of how such a "harmless" MEV model can be structured. In this scenario, although MEV and Arbitrage bots continue to exist, their profits are reduced while Liquidity Providers (LPs) earn more. As LPs stand to gain more, it's likely that the pool will attract additional LPs to supply liquidity. This increase in liquidity providers should, in turn, lead to lower fees for users’ trade.
