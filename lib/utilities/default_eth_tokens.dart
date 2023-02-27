import 'package:stackwallet/models/ethereum/erc20_token.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';

abstract class DefaultTokens {
  static List<EthToken> list = [
    Erc20Token(
      contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      name: "USD Coin",
      symbol: "USDC",
      decimals: 18,
      balance: 0,
    ),
    Erc20Token(
      contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
      name: "Tether",
      symbol: "USDT",
      decimals: 18,
      balance: 0,
    ),
    Erc20Token(
      contractAddress: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
      name: "Shiba Inu",
      symbol: "SHIB",
      decimals: 18,
      balance: 0,
    ),
    Erc20Token(
      contractAddress: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
      name: "BNB Token",
      symbol: "BNB",
      decimals: 18,
      balance: 0,
    ),
    Erc20Token(
      contractAddress: "0x4Fabb145d64652a948d72533023f6E7A623C7C53",
      name: "BUSD",
      symbol: "BUSD",
      decimals: 18,
      balance: 0,
    ),
    Erc20Token(
      contractAddress: "0x514910771af9ca656af840dff83e8264ecf986ca",
      name: "Chainlink",
      symbol: "LINK",
      decimals: 18,
      balance: 0,
    ),
  ];
}
