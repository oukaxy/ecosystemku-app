import '../database.dart';

class FinanceDao {
  FinanceDao(this.db);

  final AppDatabase db;

  Future<List<Book>> books() => db.select(db.books).get();

  Future<List<BookAccount>> bookAccounts() => db.select(db.bookAccounts).get();

  Future<List<Account>> accounts() => db.select(db.accounts).get();

  Future<List<CategoryFinance>> categories() =>
      db.select(db.categoriesFinance).get();

  Future<List<FinanceTransaction>> transactions() =>
      db.select(db.financeTransactions).get();

  Future<List<Member>> members() => db.select(db.members).get();

  Future<List<MasterBudget>> masterBudgets() =>
      db.select(db.masterBudgets).get();

  Future<List<SavingsPot>> savingsPots() => db.select(db.savingsPots).get();

  Future<List<SavingsEvent>> savingsEvents() =>
      db.select(db.savingsEvents).get();

  Future<void> clearAll() async {
    await db.delete(db.savingsEvents).go();
    await db.delete(db.savingsPots).go();
    await db.delete(db.masterBudgets).go();
    await db.delete(db.budgetsLegacy).go();
    await db.delete(db.financeTransactions).go();
    await db.delete(db.bookAccounts).go();
    await db.delete(db.accounts).go();
    await db.delete(db.books).go();
    await db.delete(db.categoriesFinance).go();
    await db.delete(db.members).go();
  }
}
