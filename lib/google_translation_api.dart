import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/gak.dart';
import 'headers_api_request.dart';

class GoogleTranslationApi {
  // Call to Google Translation API.

  late SharedPreferences prefs;

  Future<String> translate({
    required String original_text,
    required String source_language,
    required TranslationPrintType translation_print_type,
    required int index,
    required int length,
  }) async {
    prefs = await SharedPreferences.getInstance();

    String target_language =
        prefs.getString("target_language") ?? source_language;

    String current_text = original_text;

    if (target_language == source_language) {
      current_text = original_text;

      _check_translation_print_type(
        original_text: original_text,
        returned_text: current_text,
        translation_value_Type: TranslationValueType.original,
        translation_print_type: translation_print_type,
        index: index,
        length: length,
      );
    } else {
      if (_get_local_translated_text(
            original_text: original_text,
            target_language: target_language,
          ) !=
          null) {
        current_text = prefs.getString(
            "translated_text_$original_text\_target_$target_language")!;

        _check_translation_print_type(
          original_text: original_text,
          returned_text: current_text,
          translation_value_Type: TranslationValueType.local,
          translation_print_type: translation_print_type,
          index: index,
          length: length,
        );
      } else {
        QuerySnapshot translated_text_query = await FirebaseFirestore.instance
            .collection("translations")
            .where("original_text", isEqualTo: original_text)
            .get();

        if (translated_text_query.docs.length > 0) {
          QueryDocumentSnapshot first_doc = translated_text_query.docs.first;
          var first_doc_data = first_doc.data() as Map<String, dynamic>;

          if (first_doc_data["translations"][target_language] != null) {
            String result = first_doc_data["translations"][target_language];
            first_doc.reference.update({
              "last_time_used": Timestamp.now(),
            });

            _set_local_translated_text(
              original_text: original_text,
              target_language: target_language,
              value: result,
            );

            _check_translation_print_type(
              original_text: original_text,
              returned_text: result,
              translation_value_Type: TranslationValueType.firebase,
              translation_print_type: translation_print_type,
              index: index,
              length: length,
            );
            return result;
          } else {
            return await _get_translated_text_from_api(
              original_text: original_text,
              target_language: target_language,
              source_language: source_language,
              translation_print_type: translation_print_type,
              index: index,
              length: length,
            );
          }
        } else {
          return await _get_translated_text_from_api(
            original_text: original_text,
            target_language: target_language,
            source_language: source_language,
            translation_print_type: translation_print_type,
            index: index,
            length: length,
          );
        }
      }
    }

    return current_text;
  }

  Future<String> _get_translated_text_from_api({
    required String original_text,
    required String target_language,
    required String source_language,
    required TranslationPrintType translation_print_type,
    required int index,
    required int length,
  }) async {
    try {
      Map<String, dynamic> response = await _fetch_translation_from_endpoint(
        original_text: original_text,
        target_language: target_language,
        source_language: source_language,
      );

      if (response["error"] == null) {
        var result = response['data']['translations'][0]['translatedText'];

        _set_local_translated_text(
          original_text: original_text,
          target_language: target_language,
          value: result,
        );

        _save_translated_text_in_firestore(
          original_text: original_text,
          target_language: target_language,
          value: result,
        );

        _check_translation_print_type(
          original_text: original_text,
          returned_text: result,
          translation_value_Type: TranslationValueType.api,
          translation_print_type: translation_print_type,
          index: index,
          length: length,
        );
        return result;
      } else {
        print(response["error"]);

        _check_translation_print_type(
          original_text: original_text,
          returned_text: original_text,
          translation_value_Type: TranslationValueType.original,
          translation_print_type: translation_print_type,
          index: index,
          length: length,
        );
        return original_text;
      }
    } catch (error) {
      print(error);

      _check_translation_print_type(
        original_text: original_text,
        returned_text: original_text,
        translation_value_Type: TranslationValueType.original,
        translation_print_type: translation_print_type,
        index: index,
        length: length,
      );
      return original_text;
    }
  }

  _save_translated_text_in_firestore({
    required String original_text,
    required String target_language,
    required String value,
  }) async {
    QuerySnapshot translated_text_query = await FirebaseFirestore.instance
        .collection("translations")
        .where("original_text", isEqualTo: original_text)
        .get();

    if (translated_text_query.docs.length > 0) {
      QueryDocumentSnapshot first_doc = translated_text_query.docs.first;
      var first_doc_data = first_doc.data() as Map<String, dynamic>;
      var first_doc_data_translations =
          first_doc_data["translations"] as Map<String, dynamic>;

      first_doc_data_translations[target_language] = value;

      await FirebaseFirestore.instance
          .collection("translations")
          .doc(first_doc.id)
          .update({
        "last_time_used": Timestamp.now(),
        "translations": first_doc_data_translations,
      });
    } else {
      await FirebaseFirestore.instance.collection("translations").doc().set({
        "last_time_used": Timestamp.now(),
        "original_text": original_text,
        "translations": {
          target_language: value,
        },
      });
    }
  }

  String? _get_local_translated_text({
    required String original_text,
    required String target_language,
  }) {
    return prefs
        .getString("translated_text_$original_text\_target_$target_language");
  }

  _set_local_translated_text({
    required String original_text,
    required String target_language,
    required String value,
  }) {
    prefs.setString(
        "translated_text_$original_text\_target_$target_language", value);
  }

  Future<Map<String, dynamic>> _fetch_translation_from_endpoint({
    required String original_text,
    required String target_language,
    required String source_language,
  }) async {
    String ak = await gak(
      n: "translation",
      o: "gcp",
    );

    String url =
        'https://translation.googleapis.com/language/translate/v2?source=$source_language&target=$target_language&key=$ak&q=$original_text&format=text';

    Response response = await get(
      Uri.parse(url),
      headers: await headers_api_request(),
    );
    Map<String, dynamic> reponse_body = jsonDecode(response.body);
    //print("response ${reponse_body}");
    return reponse_body;
  }

  _check_translation_print_type({
    required String original_text,
    required String returned_text,
    required TranslationValueType translation_value_Type,
    required TranslationPrintType translation_print_type,
    required int index,
    required int length,
  }) {
    String color_code = "35";

    if (translation_value_Type == TranslationValueType.local) {
      color_code = "32";
    } else if (translation_value_Type == TranslationValueType.firebase) {
      color_code = "33";
    } else if (translation_value_Type == TranslationValueType.api) {
      color_code = "31";
    }

    String message =
        "Returning translation from \x1B[${color_code}m${translation_value_Type.toShortString()}\x1B[0m";

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
}

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
    return this.toString().split('.').last;
  }
}
