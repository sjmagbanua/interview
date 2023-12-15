import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/core/database/dao/transaction/transactions_dao.dart';
import 'package:balance/core/database/database.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage(this.groupId, {super.key});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _transactionsDao = getIt.get<TransactionsDao>();

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _updateAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Group details"),
        ),
        body: StreamBuilder(
          stream: _groupsDao.watchGroup(widget.groupId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Loading...");
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(snapshot.data?.name ?? ""),
                Text(snapshot.data?.balance.toString() ?? ""),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _incomeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                        ],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          suffixText: "\$",
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final amount = int.parse(_incomeController.text);
                        final balance = snapshot.data?.balance ?? 0;
                        _groupsDao.adjustBalance(
                            balance + amount, widget.groupId);
                        _incomeController.text = "";
                        _transactionsDao.insert(amount, widget.groupId);
                      },
                      child: const Text("Add income"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expenseController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                        ],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          suffixText: "\$",
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          final amount = int.parse(_expenseController.text);
                          print('amount: $amount');
                          final balance = snapshot.data?.balance ?? 0;
                          _groupsDao.adjustBalance(
                              balance - amount, widget.groupId);
                          _expenseController.text = "";
                          _transactionsDao.insert(amount, widget.groupId);
                        },
                        child: const Text("Add expense")),
                  ],
                ),
                FutureBuilder<List<Transaction>>(
                  future:
                      _transactionsDao.getTransactionsForGroup(widget.groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        (snapshot.data as List<Transaction>).isEmpty) {
                      return const Text('No transactions');
                    } else {
                      var transactions = snapshot.data as List<Transaction>;
                      return Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return ListTile(
                              leading: Column(
                                children: [
                                  const Text('Transaction'),
                                  Text(
                                    transaction.createdAt.toString(),
                                    style: const TextStyle(color: Colors.red),
                                  )
                                ],
                              ),
                              title: Text('Amount: ${transaction.amount}'),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Update Amount'),
                                      content: TextFormField(
                                        controller: _updateAmountController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r"[0-9]")),
                                        ],
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          suffixText: '\$',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final newAmount = int.parse(
                                                _updateAmountController.text);
                                            final transactionId =
                                                transaction.id;

                                            await _transactionsDao
                                                .updateTransactionAmount(
                                                    transactionId, newAmount);

                                            final updatedTransactions =
                                                await _transactionsDao
                                                    .getTransactionsForGroup(
                                                        widget.groupId);

                                            setState(() {
                                              transactions =
                                                  updatedTransactions;
                                            });

                                            Navigator.pop(context);
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    }
                  },
                )
              ],
            );
          },
        ),
      );
}
