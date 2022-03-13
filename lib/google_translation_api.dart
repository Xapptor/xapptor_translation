import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/gak.dart';
import 'headers_api_request.dart';

class GoogleTranslationApi {
  // Call to Google Translation API.

  late SharedPreferences prefs;

  Future<String> translate(String original_text) async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.getString("target_language") == null)
      prefs.setString("target_language", "en");
    String target_language = prefs.getString("target_language") ?? "en";

    String current_text = original_text;

    if (target_language == "en") {
      current_text = original_text;
      print(
          "Returning translation from ${TranslationValueType.original.toShortString()}");
    } else {
      if (get_local_translated_text(
            original_text: original_text,
            target_language: target_language,
          ) !=
          null) {
        current_text = prefs.getString(
            "translated_text_$original_text\_target_$target_language")!;
        print(
            "Returning translation from ${TranslationValueType.local.toShortString()}");
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

            set_local_translated_text(
              original_text: original_text,
              target_language: target_language,
              value: result,
            );

            print(
                "Returning translation from ${TranslationValueType.firebase.toShortString()}");
            return result;
          } else {
            return await get_translated_text_from_api(
              original_text: original_text,
              target_language: target_language,
            );
          }
        } else {
          return await get_translated_text_from_api(
            original_text: original_text,
            target_language: target_language,
          );
        }
      }
    }

    return current_text;
  }

  Future<String> get_translated_text_from_api({
    required String original_text,
    required String target_language,
  }) async {
    try {
      Map<String, dynamic> response = await fetch_translation_from_endpoint(
        original_text: original_text,
        target_language: target_language,
      );

      if (response["error"] == null) {
        var result = response['data']['translations'][0]['translatedText'];

        set_local_translated_text(
          original_text: original_text,
          target_language: target_language,
          value: result,
        );

        save_translated_text_in_firestore(
          original_text: original_text,
          target_language: target_language,
          value: result,
        );
        print(
            "Returning translation from ${TranslationValueType.api.toShortString()}");
        return result;
      } else {
        print(response["error"]);
        print(
            "Returning translation from ${TranslationValueType.original.toShortString()}");
        return original_text;
      }
    } catch (error) {
      print(error);
      print(
          "Returning translation from ${TranslationValueType.original.toShortString()}");
      return original_text;
    }
  }

  save_translated_text_in_firestore({
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

  String? get_local_translated_text({
    required String original_text,
    required String target_language,
  }) {
    return prefs
        .getString("translated_text_$original_text\_target_$target_language");
  }

  set_local_translated_text({
    required String original_text,
    required String target_language,
    required String value,
  }) {
    prefs.setString(
        "translated_text_$original_text\_target_$target_language", value);
  }

  Future<Map<String, dynamic>> fetch_translation_from_endpoint({
    required String original_text,
    required String target_language,
  }) async {
    String ak = await gak(
      n: "translation",
      o: "gcp",
    );

    String url =
        'https://translation.googleapis.com/language/translate/v2?source=en&target=$target_language&key=$ak&q=$original_text&format=text';

    Response response = await get(
      Uri.parse(url),
      headers: await headers_api_request(),
    );
    Map<String, dynamic> reponse_body = jsonDecode(response.body);
    //print("response ${reponse_body}");
    return reponse_body;
  }
}

enum TranslationValueType {
  api,
  firebase,
  original,
  local,
}

extension ParseToString on TranslationValueType {
  String toShortString() {
    return this.toString().toLowerCase().split('.').last;
  }
}
