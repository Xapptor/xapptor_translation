/// Language detection module for xapptor_translation.
///
/// This module provides automatic language detection based on the user's IP address.
/// It detects the user's country and maps it to the appropriate language code.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:xapptor_translation/language_detection/language_detection.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   // Auto-detect and set language based on IP
///   final result = await auto_detect_language();
///   print('Language set to: ${result.language_code} (source: ${result.source})');
///
///   runApp(MyApp());
/// }
/// ```
///
/// ## Features
///
/// - Automatic country detection via IP geolocation
/// - Multiple fallback API providers for reliability
/// - 24-hour caching to minimize API calls
/// - Respects user's manual language preference
/// - Configurable supported languages list
/// - Graceful fallback on detection failure
///
/// ## Privacy Considerations
///
/// This module sends the user's IP address to third-party geolocation services
/// to determine their country. Only the country code is stored locally; no other
/// location data is persisted. The module:
///
/// - Prioritizes HTTPS providers for secure transmission
/// - Stores only: detected language code, country code, and detection timestamp
/// - Does not transmit any personally identifiable information beyond IP
/// - Caches results to minimize external API calls
///
/// If your app requires strict privacy compliance (GDPR, etc.), consider
/// obtaining user consent before calling [auto_detect_language].
library language_detection;

export 'auto_detect_language.dart';
export 'country_to_language.dart';
export 'ip_language_detector.dart';
