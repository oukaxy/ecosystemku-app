class LinkkuSummary {
  const LinkkuSummary({required this.total, required this.privateCount});

  const LinkkuSummary.empty()
      : total = 0,
        privateCount = 0;

  final int total;
  final int privateCount;
}
