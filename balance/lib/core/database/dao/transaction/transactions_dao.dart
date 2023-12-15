import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future insert(int amount, String groupId) {
    return into(transactions).insert(
      TransactionsCompanion.insert(
        id: const Uuid().v1(),
        amount: Value(amount),
        createdAt: DateTime.now(),
        groupId: groupId,
      ),
    );
  }

  Future insertExpense(int amount, String groupId) {
    return into(transactions).insert(
      TransactionsCompanion.insert(
        id: const Uuid().v1(),
        createdAt: DateTime.now(),
        amount: Value(-amount),
        groupId: groupId,
      ),
    );
  }

  Future updateTransactionAmount(String transactionId, int newAmount) {
    return (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(TransactionsCompanion(
      amount: Value(newAmount),
    ));
  }

  Future<List<Transaction>> getTransactionsForGroup(String groupId) async {
    return (select(transactions)..where((t) => t.groupId.equals(groupId)))
        .get();
  }
}
