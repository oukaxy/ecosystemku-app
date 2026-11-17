class IdekuSummary {
  const IdekuSummary({
    required this.total,
    required this.open,
    required this.latestTitle,
  });

  const IdekuSummary.empty()
      : total = 0,
        open = 0,
        latestTitle = null;

  final int total;
  final int open;
  final String? latestTitle;
}
