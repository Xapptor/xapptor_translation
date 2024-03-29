import 'dart:async';
import 'dart:core';
import 'package:xapptor_logic/clean_share_preferences_cache.dart';
import 'package:xapptor_translation/model/enum.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  translate({
    int cache_lifetime_in_seconds = Duration.secondsPerDay * 30,
    required int source_language_index,
    required int length,
  }) async {
    clean_share_preferences_cache(
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

      String translated_text = await TranslationManager().translate(
        original_text: original_texts[i],
        source_language: translation_text_list_array
            .list[source_language_index].source_language,
        translation_print_type: TranslationPrintType.none,
        length: length,
      );

      stream_controllers[i].add(translated_text);
    }
  }
}
