class KronikSummary {
  const KronikSummary({required this.date, required this.title});

  const KronikSummary.empty()
      : date = null,
        title = null;

  final String? date;
  final String? title;

  bool get isEmpty => title == null;
}
