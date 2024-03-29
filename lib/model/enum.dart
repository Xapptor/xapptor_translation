enum TranslationValueType {
  api,
  firebase,
  original,
  local,
}

enum TranslationPrintType {
  none,
  all,
  first,
  last,
}

extension ParseToString on TranslationValueType {
  String toShortString() {
    return toString().split('.').last;
  }
}
