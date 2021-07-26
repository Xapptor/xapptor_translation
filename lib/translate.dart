import 'dart:async';
import 'dart:core';
import 'google_translation_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationStream {
  List<StreamController<String>> stream_controllers = [];
  List<Stream> streams = [];
  List<String> original_texts = [];
  late SharedPreferences prefs;

  TranslationStream({
    required List<String> text_list,
    required Function({
      required int index,
      required String new_text,
      required int list_index,
    })
        update_text_list_function,
    required int list_index,
    required bool active_translation,
  }) {
    for (int i = 0; i < text_list.length; i++) {
      original_texts.add(text_list[i]);

      stream_controllers.add(
        StreamController<String>(),
      );
      streams.add(
        stream_controllers[i].stream,
      );

      streams.last.listen((new_text) {
        update_text_list_function(
          index: i,
          new_text: new_text,
          list_index: list_index,
        );
      });

      stream_controllers.last.add(
        original_texts[i],
      );
    }
    if (active_translation) {
      Timer(Duration(milliseconds: 300), () {
        translate();
      });
    }
  }

  translate() async {
    prefs = await SharedPreferences.getInstance();

    // prefs.setString(
    //   "last_date_translations_updated",
    //   DateTime.now().subtract(Duration(days: 31)).toString(),
    // );

    if (prefs.getString("last_date_translations_updated") == null) {
      prefs.setString(
        "last_date_translations_updated",
        DateTime.now().toString(),
      );
    } else {
      DateTime last_date_translations_updated =
          DateTime.parse(prefs.getString("last_date_translations_updated")!);

      int date_difference_in_days =
          DateTime.now().difference(last_date_translations_updated).inDays;

      //print("date_difference_in_days $date_difference_in_days");

      if (date_difference_in_days > 30) {
        final prefs_keys = prefs.getKeys();
        for (String prefs_key in prefs_keys) {
          if (prefs_key.contains("translated_text_")) {
            prefs.remove(prefs_key);
          }
        }
        prefs.remove("last_date_translations_updated");
        prefs.remove("languages_names");
        prefs.remove("languages_codes");
      }
    }

    for (int i = 0; i < original_texts.length; i++) {
      stream_controllers[i].add(
        await GoogleTranslationApi().translate(original_texts[i]),
      );
    }
  }
}
