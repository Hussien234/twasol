import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/credentials.dart';//web3 its connect the flutter with Ethereum nodes and smart contracts from web applications.
import 'dart:io' show Platform;
class EthereumService {
  static final EthereumService _instance = EthereumService._internal();
  late Web3Client _client;

  factory EthereumService() {
    return _instance;
  }

  EthereumService._internal();

  Future<void> connectToEthereum() async {
    final String infuraUrl = "https://mainnet.infura.io/v3/9c6cf06071e34649af47126278d42c95";
    _client = Web3Client(infuraUrl, http.Client());

    // Add more initialization code as needed
  }
  // Replace with the actual ABI for ChatContract
  static const String YOUR_CONTRACT_ABI_CHAT = '[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"string","name":"content","type":"string"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"MessageSent","type":"event"},{"inputs":[{"internalType":"string","name":"_content","type":"string"}],"name":"sendMessage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_user","type":"address"}],"name":"getMessages","outputs":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"string","name":"content","type":"string"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"internalType":"struct ChatContract.Message[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"messages","outputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"string","name":"content","type":"string"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"stateMutability":"view","type":"function"}]';

  // Replace with the actual ABI for UserContract
  static const String YOUR_CONTRACT_ABI_USER = '[{"inputs":[],"name":"addUser","outputs":[],"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"}],"name":"UserAdded","type":"event"},{"inputs":[],"name":"getUsers","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"users","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]';

  Future<void> sendMessage(String content) async {
    final String contractAddress = "0xDA0bab807633f07f013f94DD0E6A4F96F8742B53";

    // Retrieve private key from environment variable
    final String privateKey = Platform.environment['9c6cf06071e34649af47126278d42c95'] ?? "9c6cf06071e34649af47126278d42c95";

    if (privateKey.isEmpty) {
      throw Exception("Private key not provided.");
    }

    final Credentials credentials = await _client.credentialsFromPrivateKey(privateKey);

    final DeployedContract contract = DeployedContract(
      ContractAbi.fromJson(YOUR_CONTRACT_ABI_CHAT, 'ChatContract'),
      EthereumAddress.fromHex(contractAddress),
    );

    final Transaction transaction = Transaction(
      from: await credentials.extractAddress(),
      to: contract.address,
      gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
      maxGas: 22000,
      value: EtherAmount.zero(),
      data: contract.function('sendMessage').encodeCall([content]),
    );

    await _client.sendTransaction(credentials, transaction);
  }

  Future<List<String>> getMessages() async {
    final String contractAddress = "0xDA0bab807633f07f013f94DD0E6A4F96F8742B53";
    final ContractAbi contractABI = ContractAbi.fromJson(YOUR_CONTRACT_ABI_CHAT, 'ChatContract');
    final DeployedContract contract = DeployedContract(contractABI, EthereumAddress.fromHex(contractAddress));

    final EthereumAddress userAddress = EthereumAddress.fromHex("0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47");
    final ContractFunction function = contract.function('getMessages');
    final List<dynamic> result = await _client.call(
      contract: contract,
      function: function,
      params: [userAddress],
    );

    return result.map((msg) => msg['content'].toString()).toList();
  }

}
