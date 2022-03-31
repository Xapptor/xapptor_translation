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
    this.translation_text_list_array,
  );

  final List<TranslationTextList> translation_text_list_array;

  List<String> get(int source_language_index) {
    return this.translation_text_list_array[source_language_index].text_list;
  }
}
