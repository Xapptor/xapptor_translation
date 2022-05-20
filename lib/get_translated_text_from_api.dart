import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_translation/fetch_translation_from_endpoint.dart';
import 'package:xapptor_translation/model/enum.dart';
import 'package:xapptor_translation/print_translation_info.dart';
import 'package:xapptor_translation/save_translated_text_in_firestore.dart';
import 'package:xapptor_translation/set_local_translated_text.dart';

Future<String> get_translated_text_from_api({
  required String original_text,
  required String target_language,
  required String source_language,
  required TranslationPrintType translation_print_type,
  required SharedPreferences prefs,
  required int legnth,
}) async {
  try {
    Map<String, dynamic> response = await fetch_translation_from_endpoint(
      original_text: original_text,
      target_language: target_language,
      source_language: source_language,
    );

    if (response["error"] == null) {
      var result = response['data']['translations'][0]['translatedText'];

      set_local_translated_text(
        original_text: original_text,
        target_language: target_language,
        value: result,
        prefs: prefs,
      );

      save_translated_text_in_firestore(
        original_text: original_text,
        target_language: target_language,
        value: result,
      );

      print_translation_info(
        original_text: original_text,
        returned_text: result,
        translation_value_Type: TranslationValueType.api,
        translation_print_type: translation_print_type,
        length: legnth,
      );
      return result;
    } else {
      print(response["error"]);

      print_translation_info(
        original_text: original_text,
        returned_text: original_text,
        translation_value_Type: TranslationValueType.original,
        translation_print_type: translation_print_type,
        length: legnth,
      );
      return original_text;
    }
  } catch (error) {
    print(error);

    print_translation_info(
      original_text: original_text,
      returned_text: original_text,
      translation_value_Type: TranslationValueType.original,
      translation_print_type: translation_print_type,
      length: legnth,
    );
    return original_text;
  }
}
