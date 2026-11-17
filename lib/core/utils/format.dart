String pluralize(int count, String singular, [String? plural]) =>
    count == 1 ? singular : (plural ?? singular);

String formatCount(int count) => count.toString();
