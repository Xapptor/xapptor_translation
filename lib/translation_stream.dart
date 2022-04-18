import 'dart:async';
import 'dart:core';
import 'package:xapptor_logic/check_share_preferences_cache.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'google_translation_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TranslationStream model.

class TranslationStream {
  List<StreamController<String>> stream_controllers = [];
  List<Stream> streams = [];
  List<String> original_texts = [];
  late SharedPreferences prefs;
  TranslationTextListArray translation_text_list_array;

  TranslationStream({
    required this.translation_text_list_array,
    required Function({
      required int index,
      required String new_text,
      required int list_index,
    })
        update_text_list_function,
    required int list_index,
    bool enable_initial_translation = false,
    int cache_lifetime_in_seconds = Duration.secondsPerDay * 30,
    required int source_language_index,
  }) {
    for (int i = 0;
        i < translation_text_list_array.get(source_language_index).length;
        i++) {
      original_texts
          .add(translation_text_list_array.get(source_language_index)[i]);

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
    if (enable_initial_translation) {
      Timer(Duration(milliseconds: 300), () {
        translate(
          cache_lifetime_in_seconds: cache_lifetime_in_seconds,
          source_language_index: source_language_index,
        );
      });
    }
  }

  translate({
    int cache_lifetime_in_seconds = Duration.secondsPerDay * 30,
    required int source_language_index,
  }) async {
    check_share_preferences_cache(
      key_to_check: "last_date_translations_updated",
      similar_keys_to_delete: "translated_text_",
      specific_keys_to_delete: [
        "languages_names",
        "languages_codes",
      ],
      cache_lifetime_in_seconds: cache_lifetime_in_seconds,
    );

    original_texts.clear();

    for (int i = 0; i < streams.length; i++) {
      original_texts
          .add(translation_text_list_array.get(source_language_index)[i]);

      String translated_text = await GoogleTranslationApi().translate(
        original_text: original_texts[i],
        source_language: translation_text_list_array
            .translation_text_list_array[source_language_index].source_language,
        translation_print_type: TranslationPrintType.none,
        index: i,
        length: streams.length,
      );

      stream_controllers[i].add(translated_text);
    }
  }
}
