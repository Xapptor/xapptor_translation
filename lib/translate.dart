import 'dart:async';
import 'dart:core';
import 'package:xapptor_logic/clean_share_preferences.dart';
import 'google_translation_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TranslationStream model.

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
    check_share_preferences_cache(
      key_to_check: "last_date_translations_updated",
      similar_keys_to_delete: "translated_text_",
      specific_keys_to_delete: [
        "languages_names",
        "languages_codes",
      ],
      cache_life_period_in_seconds: Duration.secondsPerDay * 30,
    );

    for (int i = 0; i < original_texts.length; i++) {
      stream_controllers[i].add(
        await GoogleTranslationApi().translate(original_texts[i]),
      );
    }
  }
}
