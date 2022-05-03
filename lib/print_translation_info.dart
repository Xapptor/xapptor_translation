import 'package:xapptor_logic/change_color_by_priority.dart';
import 'package:xapptor_translation/model/enum.dart';

int original_counter = 0;
int local_counter = 0;
int firebase_counter = 0;
int api_counter = 0;
int index = 0;

print_translation_info({
  required String original_text,
  required String returned_text,
  required TranslationValueType translation_value_Type,
  required TranslationPrintType translation_print_type,
  required int length,
}) {
  TextPriority text_priority = TextPriority.low;

  if (translation_value_Type == TranslationValueType.original) {
    text_priority = TextPriority.low;

    original_counter++;
  } else if (translation_value_Type == TranslationValueType.local) {
    text_priority = TextPriority.medium;

    local_counter++;
  } else if (translation_value_Type == TranslationValueType.firebase) {
    text_priority = TextPriority.high;

    firebase_counter++;
  } else if (translation_value_Type == TranslationValueType.api) {
    text_priority = TextPriority.urgent;

    api_counter++;
  }

  index++;

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

      if (index == length) {
        print_counters(length: length);
      }
      break;
    case TranslationPrintType.first:
      if (index == 1) {
        print(message);
        print(original_text_message);
        print(returned_text_message);
      }

      if (index == length) {
        print_counters(length: length);
      }
      break;
    case TranslationPrintType.last:
      if (index == length) {
        print(message);
        print(original_text_message);
        print(returned_text_message);

        print_counters(length: length);
      }
      break;
  }
}

print_counters({
  required int length,
}) {
  if (original_counter > 0) {
    String message =
        "Translated $original_counter original texts, size ${length}";

    String message_with_color_priority =
        change_color_by_priority(message, TextPriority.low);

    print(message_with_color_priority);
  }

  if (local_counter > 0) {
    String message = "Translated $local_counter local texts, size ${length}";

    String message_with_color_priority =
        change_color_by_priority(message, TextPriority.medium);

    print(message_with_color_priority);
  }

  if (firebase_counter > 0) {
    String message =
        "Translated $firebase_counter firebase texts, size ${length}";

    String message_with_color_priority =
        change_color_by_priority(message, TextPriority.high);

    print(message_with_color_priority);
  }

  if (api_counter > 0) {
    String message = "Translated $api_counter api texts, size ${length}";

    String message_with_color_priority =
        change_color_by_priority(message, TextPriority.urgent);

    print(message_with_color_priority);
  }

  index = 0;
  original_counter = 0;
  local_counter = 0;
  firebase_counter = 0;
  api_counter = 0;
}
