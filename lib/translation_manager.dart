import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_translation/get_local_translated_text.dart';
import 'package:xapptor_translation/get_translated_text_from_api.dart';
import 'package:xapptor_translation/print_translation_info.dart';
import 'package:xapptor_translation/model/enum.dart';
import 'package:xapptor_translation/set_local_translated_text.dart';

class TranslationManager {
  Future<String> translate({
    required String original_text,
    required String source_language,
    required TranslationPrintType translation_print_type,
    required int length,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String target_language =
        prefs.getString("target_language") ?? source_language;

    String current_text = original_text;

    if (target_language == source_language) {
      current_text = original_text;

      print_translation_info(
        original_text: original_text,
        returned_text: current_text,
        translation_value_Type: TranslationValueType.original,
        translation_print_type: translation_print_type,
        length: length,
      );
    } else {
      if (get_local_translated_text(
            original_text: original_text,
            target_language: target_language,
            prefs: prefs,
          ) !=
          null) {
        current_text = prefs.getString(
            "translated_text_$original_text\_target_$target_language")!;

        print_translation_info(
          original_text: original_text,
          returned_text: current_text,
          translation_value_Type: TranslationValueType.local,
          translation_print_type: translation_print_type,
          length: length,
        );
      } else {
        QuerySnapshot translated_text_query = await FirebaseFirestore.instance
            .collection("translations")
            .where("original_text", isEqualTo: original_text)
            .get();

        if (translated_text_query.docs.isNotEmpty) {
          QueryDocumentSnapshot first_doc = translated_text_query.docs.first;
          var first_doc_data = first_doc.data() as Map<String, dynamic>;

          if (first_doc_data["translations"][target_language] != null) {
            String result = first_doc_data["translations"][target_language];
            first_doc.reference.update({
              "last_time_used": Timestamp.now(),
            });

            set_local_translated_text(
              original_text: original_text,
              target_language: target_language,
              value: result,
              prefs: prefs,
            );

            print_translation_info(
              original_text: original_text,
              returned_text: result,
              translation_value_Type: TranslationValueType.firebase,
              translation_print_type: translation_print_type,
              length: length,
            );
            return result;
          } else {
            return await get_translated_text_from_api(
              original_text: original_text,
              target_language: target_language,
              source_language: source_language,
              translation_print_type: translation_print_type,
              prefs: prefs,
              legnth: length,
            );
          }
        } else {
          return await get_translated_text_from_api(
            original_text: original_text,
            target_language: target_language,
            source_language: source_language,
            translation_print_type: translation_print_type,
            prefs: prefs,
            legnth: length,
          );
        }
      }
    }

    return current_text;
  }
}
