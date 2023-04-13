import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_web_metamask/src/helpers/helper.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  String account = '';
  var balanceETH = '0';
  var balanceUSD = '0';
  var isConnected = false;

  final bankAddress = "0x73C77f3EE2f5f10929bF69A83e59fdef98784e0b";
  final bankAbi = '[{"inputs":[],"name":"deposit","outputs":[],"stateMutability":"payable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Deposit","type":"event"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Withdraw","type":"event"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]';

  Contract? bankContract;

  final depositKey = GlobalKey<FormState>();
  final withdrawKey = GlobalKey<FormState>();

  final depositInputController = TextEditingController(text: "1");
  final withdrawInputController = TextEditingController(text: "1");


  /// incializar o contrato
  void connectContract() {
    bankContract = Contract(bankAddress, bankAbi, provider!.getSigner());

    bankContract!.on('Deposit', (owner, amount, event) {
      // ignore: avoid_print
      print('Deposit: $owner = $amount');
    });

    bankContract!.on('Withdraw', (owner, amount, event) {
      // ignore: avoid_print
      print('Withdraw: $owner = $amount');
    });
  }

  /// formulario de deposito
  void depositForm() async {
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deposit (ETH)'),
          content: Form(
            key: depositKey,
            child: TextFormField(
              controller: depositInputController,
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty ? "required" : null,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                if (!(depositKey.currentState?.validate() ?? false)) return;

                //TODO: deposit action
                final amount = double.parse(depositInputController.text) * pow(10, 18);
                depositInputController.text = '1';
                Navigator.of(context).pop();

                try {
                  final tx = await bankContract!.send('deposit', [], TransactionOverride(value: BigInt.from(amount)));
                  html.window.open('$explorerTxUrl/${tx.hash}', '_blank');
                } catch (ex) {
                  await showDialogError(context: context, message: ethereumException(ex));
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                depositInputController.text = '1';
                Navigator.of(context).pop();
              },
            ),
          ],
        )
    );
  }

  void checkBalanceBank() async {
    //TODO: check balance action
    var bankBalanceEth = "0";
    var bankBalanceUsd = "0";
    try {
      final bankBalance = await bankContract!.call<BigInt>('balance');
      bankBalanceEth = weiToEth(bankBalance);
      bankBalanceUsd = weiToUsd(bankBalance);
    } catch (ex) {
      await showDialogError(context: context, message: ethereumException(ex));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '$bankBalanceEth ETH',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Eq: \$$bankBalanceUsd',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// formulario de saque
  void withdrawForm() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw (ETH)'),
        content: Form(
          key: withdrawKey,
          child: TextFormField(
            controller: withdrawInputController,
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? "required" : null,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () async {
              if (!(withdrawKey.currentState?.validate() ?? false)) return;

              //TODO: withdraw action
              final amount = double.parse(withdrawInputController.text) * pow(10, 18);
              withdrawInputController.text = '1';
              Navigator.of(context).pop();

              try {
                final tx = await bankContract!.send('withdraw', [amount.toString()]);
                html.window.open('$explorerTxUrl/${tx.hash}', '_blank');
              } catch (ex) {
                await showDialogError(context: context, message: ethereumException(ex));
              }
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              withdrawInputController.text = '1';
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// verifica o saldo
  Future checkBalance() async {
    final balanceWei = await provider!.getSigner().getBalance();
    setState(() {
      balanceETH = weiToEth(balanceWei);
      balanceUSD = weiToUsd(balanceWei);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xfff2f4f6),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.08),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    primary: Colors.lightBlue,
                    side: const BorderSide(
                      color: Colors.lightBlue,
                    ),
                  ),
                  onPressed: () async {
                    if(!isConnected) {
                      if(ethereum == null) {
                        EasyLoading.showError('No metamask');
                        return;
                      }

                      if (ethereum != null) {
                        try {
                          final accounts = await ethereum!.requestAccount();

                          setState(() {
                            account = accounts[0];
                            isConnected = true;
                          });

                          connectContract();

                          ethereum!.onChainChanged((chainId) async {
                            await checkBalance();
                          });

                          ethereum!.onAccountsChanged((accounts) async {
                            setState(() {
                              account = accounts[0];
                            });

                            await checkBalance();
                          });
                        } on EthereumUserRejected { }
                      }
                    }else{

                    }

                    await checkBalance();
                  },
                  child: isConnected ? const Text("Refresh") : const Text("Connect"),
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 2,
                child: Column(
                  children: [
                    headerCard(),
                    const Divider(),
                    const SizedBox(height: 20),
                    centerBalance(),
                    const SizedBox(height: 20),
                    actionsButtons()

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  actionsButtons() {
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => depositForm(),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 10),
              const Text("Deposit", style: TextStyle(color: Colors.blue))
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => withdrawForm(),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 10),
              Text("Withdraw", style: TextStyle(color: Colors.blue))
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => checkBalanceBank(),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.attach_money),
              ),

              const SizedBox(height: 10),
              Text("Balance", style: TextStyle(color: Colors.blue))
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => html.window.open('$explorerAddressUrl/$bankAddress', '_blank'),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.account_balance),
              ),
              const SizedBox(height: 10),
              const Text("Bank", style: TextStyle(color: Colors.blue))
            ],
          ),
        ],
      ),
    );
  }

  centerBalance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text("$balanceETH ETH", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("\$ $balanceUSD USD", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  headerCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: () {}, child: Container()),
            Column(
              children: [
                Text("Account 1", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(account, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            TextButton(onPressed: () {}, child: Icon(Icons.more_vert, color: Colors.grey))
          ],
        ),
      ),
    );
  }
}
