class FinanceSummary {
  const FinanceSummary({
    required this.balance,
    required this.expenseToday,
    required this.incomeToday,
  });

  const FinanceSummary.empty()
      : balance = 0,
        expenseToday = 0,
        incomeToday = 0;

  final int balance;
  final int expenseToday;
  final int incomeToday;
}
