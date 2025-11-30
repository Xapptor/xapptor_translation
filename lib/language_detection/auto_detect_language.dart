import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_translation/language_detection/country_to_language.dart';
import 'package:xapptor_translation/language_detection/ip_language_detector.dart';

/// Result of the auto-detection process.
@immutable
class AutoDetectLanguageResult {
  /// Whether the detection was successful.
  final bool success;

  /// The detected or fallback language code.
  final String language_code;

  /// The source of the language (detected, cached, fallback).
  final LanguageSource source;

  /// The country code if detected.
  final String? country_code;

  /// Error message if detection failed.
  final String? error_message;

  const AutoDetectLanguageResult({
    required this.success,
    required this.language_code,
    required this.source,
    this.country_code,
    this.error_message,
  });

  @override
  String toString() {
    return 'AutoDetectLanguageResult(success: $success, language: $language_code, source: $source, country: $country_code)';
  }
}

/// Source of the detected language.
enum LanguageSource {
  /// Language was detected from IP geolocation.
  detected,

  /// Language was loaded from cache (user previously set it).
  cached,

  /// Fallback language was used due to detection failure.
  fallback,

  /// User had already set a language preference.
  user_preference,
}

/// Configuration for auto language detection.
class AutoDetectConfig {
  /// The fallback language code if detection fails.
  final String fallback_language;

  /// Whether to override existing user preference.
  /// If false (default), respects user's manual language choice.
  final bool override_user_preference;

  /// Timeout for IP detection API calls.
  final Duration timeout;

  /// Whether to enable debug logging.
  final bool enable_debug_logs;

  /// List of supported language codes. If provided, detected language
  /// will only be set if it's in this list, otherwise fallback is used.
  final List<String>? supported_languages;

  /// How long to cache the IP detection result before refreshing.
  /// Default is 24 hours.
  final Duration cache_duration;

  const AutoDetectConfig({
    this.fallback_language = 'en',
    this.override_user_preference = false,
    this.timeout = const Duration(seconds: 5),
    this.enable_debug_logs = false,
    this.supported_languages,
    this.cache_duration = const Duration(hours: 24),
  });
}

/// Automatically detects and sets the recommended language based on user's IP.
///
/// This function should be called during app initialization, typically in `main()`
/// after Firebase initialization but before `runApp()`.
///
/// ## Behavior
///
/// 1. If the user has already set a language preference, it's respected (unless
///    `override_user_preference` is true)
/// 2. If a recent cached detection exists (within `cache_duration`), it's reused
/// 3. Otherwise, performs IP geolocation to detect the user's country
/// 4. Maps the country to the most common language and sets it as `target_language`
///
/// ## Limitations
///
/// - **VPN users**: Will detect the VPN server's country, not the user's actual location
/// - **Shared/corporate IPs**: May not reflect individual user's location
/// - **Offline mode**: Will use fallback language if no network is available
///
/// ## Example usage
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   // Auto-detect language based on IP
///   await auto_detect_language();
///
///   runApp(MyApp());
/// }
/// ```
///
/// With custom configuration:
/// ```dart
/// await auto_detect_language(
///   config: AutoDetectConfig(
///     fallback_language: 'es',
///     supported_languages: ['en', 'es', 'fr', 'de'],
///     enable_debug_logs: true,
///   ),
/// );
/// ```
Future<AutoDetectLanguageResult> auto_detect_language({
  AutoDetectConfig config = const AutoDetectConfig(),
}) async {
  void log(String message) {
    if (config.enable_debug_logs) {
      debugPrint('[AutoDetectLanguage] $message');
    }
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    // Check if user already has a language preference
    final existing_language = prefs.getString('target_language');

    if (existing_language != null && !config.override_user_preference) {
      log('User already has language preference: $existing_language');
      return AutoDetectLanguageResult(
        success: true,
        language_code: existing_language,
        source: LanguageSource.user_preference,
      );
    }

    // Check if we already detected and cached the language from IP
    final cached_detected_language = prefs.getString('ip_detected_language');
    final cached_detection_time = prefs.getInt('ip_detection_timestamp');

    // Use cached detection if it's within the cache duration
    if (cached_detected_language != null && cached_detection_time != null) {
      final detection_age = DateTime.now().millisecondsSinceEpoch - cached_detection_time;
      final cache_duration_ms = config.cache_duration.inMilliseconds;

      if (detection_age < cache_duration_ms && !config.override_user_preference) {
        log('Using cached detected language: $cached_detected_language');

        // Set as target language if not already set
        if (existing_language == null) {
          await prefs.setString('target_language', cached_detected_language);
        }

        // Retrieve cached country code
        final cached_country = prefs.getString('ip_detected_country');

        return AutoDetectLanguageResult(
          success: true,
          language_code: cached_detected_language,
          source: LanguageSource.cached,
          country_code: cached_country,
        );
      }
    }

    // Perform IP-based detection
    log('Performing IP-based language detection...');
    final detector = IpLanguageDetector(
      timeout: config.timeout,
      enable_debug_logs: config.enable_debug_logs,
    );

    final location_result = await detector.detect_country();

    if (location_result.success && location_result.country_code != null) {
      // Map country to language
      var detected_language = get_language_from_country(
        location_result.country_code!,
        default_language: config.fallback_language,
      );

      log('Detected country: ${location_result.country_code}, language: $detected_language');

      // Check if detected language is in supported languages list
      if (config.supported_languages != null && !config.supported_languages!.contains(detected_language)) {
        log('Detected language $detected_language not in supported list, using fallback');
        detected_language = config.fallback_language;
      }

      // Cache the detection
      await prefs.setString('ip_detected_language', detected_language);
      await prefs.setInt('ip_detection_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('ip_detected_country', location_result.country_code!);

      // Set as target language
      await prefs.setString('target_language', detected_language);

      return AutoDetectLanguageResult(
        success: true,
        language_code: detected_language,
        source: LanguageSource.detected,
        country_code: location_result.country_code,
      );
    } else {
      // Detection failed, use fallback
      log('Detection failed: ${location_result.error_message}');

      // Only set fallback if no existing preference
      if (existing_language == null) {
        await prefs.setString('target_language', config.fallback_language);
      }

      return AutoDetectLanguageResult(
        success: false,
        language_code: existing_language ?? config.fallback_language,
        source: LanguageSource.fallback,
        error_message: location_result.error_message,
      );
    }
  } catch (e, stack_trace) {
    debugPrint('[AutoDetectLanguage] Unexpected error: $e');
    debugPrint('[AutoDetectLanguage] Stack trace: $stack_trace');

    return AutoDetectLanguageResult(
      success: false,
      language_code: config.fallback_language,
      source: LanguageSource.fallback,
      error_message: e.toString(),
    );
  }
}

/// Non-blocking version of [auto_detect_language].
///
/// This runs the detection in the background without blocking app startup.
/// Useful when you don't need to wait for the result before rendering the UI.
///
/// The [on_complete] callback is called when detection finishes.
///
/// Example:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Fire and forget - doesn't block app startup
///   auto_detect_language_in_background(
///     on_complete: (result) {
///       print('Language detected: ${result.language_code}');
///     },
///   );
///
///   runApp(MyApp());
/// }
/// ```
void auto_detect_language_in_background({
  AutoDetectConfig config = const AutoDetectConfig(),
  void Function(AutoDetectLanguageResult result)? on_complete,
}) {
  auto_detect_language(config: config).then((result) {
    on_complete?.call(result);
  });
}

/// Clears the cached IP detection data.
///
/// Use this to force a fresh detection on next app launch.
Future<void> clear_language_detection_cache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('ip_detected_language');
  await prefs.remove('ip_detection_timestamp');
  await prefs.remove('ip_detected_country');
}

/// Information about the last IP-based language detection.
@immutable
class LanguageDetectionInfo {
  /// The detected language code.
  final String language;

  /// The detected country code (if available).
  final String? country;

  /// When the detection was performed.
  final DateTime detected_at;

  /// How many hours ago the detection was performed.
  final double age_in_hours;

  const LanguageDetectionInfo({
    required this.language,
    this.country,
    required this.detected_at,
    required this.age_in_hours,
  });

  @override
  String toString() {
    return 'LanguageDetectionInfo(language: $language, country: $country, age_in_hours: ${age_in_hours.toStringAsFixed(1)})';
  }
}

/// Gets information about the last IP detection.
///
/// Returns null if no detection has been performed yet.
Future<LanguageDetectionInfo?> get_last_detection_info() async {
  final prefs = await SharedPreferences.getInstance();

  final language = prefs.getString('ip_detected_language');
  final timestamp = prefs.getInt('ip_detection_timestamp');
  final country = prefs.getString('ip_detected_country');

  if (language == null || timestamp == null) {
    return null;
  }

  final detected_at = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final age_in_hours = (DateTime.now().millisecondsSinceEpoch - timestamp) / (1000 * 60 * 60);

  return LanguageDetectionInfo(
    language: language,
    country: country,
    detected_at: detected_at,
    age_in_hours: age_in_hours,
  );
}
