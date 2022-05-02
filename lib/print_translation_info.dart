import 'package:xapptor_logic/change_color_by_priority.dart';
import 'package:xapptor_translation/model/enum.dart';

print_translation_info({
  required String original_text,
  required String returned_text,
  required TranslationValueType translation_value_Type,
  required TranslationPrintType translation_print_type,
  required int index,
  required int length,
}) {
  TextPriority text_priority = TextPriority.low;

  if (translation_value_Type == TranslationValueType.local) {
    text_priority = TextPriority.medium;
  } else if (translation_value_Type == TranslationValueType.firebase) {
    text_priority = TextPriority.high;
  } else if (translation_value_Type == TranslationValueType.api) {
    text_priority = TextPriority.urgent;
  }

  String translation_value_Type_text = change_color_by_priority(
      translation_value_Type.toShortString(), text_priority);

  String message = "Returning translation from ${translation_value_Type_text}";

  String original_text_message = "O: $original_text";
  String returned_text_message = "R: $returned_text \n";
  switch (translation_print_type) {
    case TranslationPrintType.none:
      break;
    case TranslationPrintType.all:
      print(message);
      print(original_text_message);
      print(returned_text_message);
      break;
    case TranslationPrintType.first:
      if (index == 0) {
        print(message);
        print(original_text_message);
        print(returned_text_message);
      }
      break;
    case TranslationPrintType.last:
      if (index == length) {
        print(message);
        print(original_text_message);
        print(returned_text_message);
      }
      break;
  }
}
