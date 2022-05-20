class TranslationTextList {
  TranslationTextList({
    required this.text_list,
    required this.source_language,
  });

  List<String> text_list;
  String source_language;
}

class TranslationTextListArray {
  TranslationTextListArray(
    this.list,
  );

  final List<TranslationTextList> list;

  List<String> get(int source_language_index) {
    return this.list[source_language_index].text_list;
  }
}
