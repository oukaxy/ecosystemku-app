import '../../../core/db/clock.dart';
import '../../../core/db/daos/finance_dao.dart';
import 'finance_summary.dart';

class FinanceRepository {
  FinanceRepository(this.dao);

  final FinanceDao dao;

  Future<FinanceSummary> summary(DateTime day) async {
    final accounts = await dao.accounts();
    final transactions = await dao.transactions();
    final date = dateString(day);

    var balance = 0;
    for (final account in accounts) {
      balance += account.balance;
    }

    var expense = 0;
    var income = 0;
    for (final trx in transactions) {
      if (trx.date != date) continue;
      if (trx.transferPair != null && trx.transferPair!.isNotEmpty) continue;
      if (trx.direction == 'out') {
        expense += trx.amount;
      } else if (trx.direction == 'in') {
        income += trx.amount;
      }
    }

    return FinanceSummary(
      balance: balance,
      expenseToday: expense,
      incomeToday: income,
    );
  }
}
