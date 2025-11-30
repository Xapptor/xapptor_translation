import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result model for IP-based geolocation detection.
@immutable
class IpLocationResult {
  final bool success;
  final String? country_code;
  final String? country_name;
  final String? city;
  final String? error_message;

  const IpLocationResult({
    required this.success,
    this.country_code,
    this.country_name,
    this.city,
    this.error_message,
  });

  factory IpLocationResult.success({
    required String country_code,
    String? country_name,
    String? city,
  }) {
    return IpLocationResult(
      success: true,
      country_code: country_code,
      country_name: country_name,
      city: city,
    );
  }

  factory IpLocationResult.failure(String error_message) {
    return IpLocationResult(
      success: false,
      error_message: error_message,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'IpLocationResult(country: $country_code - $country_name, city: $city)';
    }
    return 'IpLocationResult(error: $error_message)';
  }
}

/// Detects user's location based on their IP address using free geolocation APIs.
///
/// This class provides multiple fallback providers to ensure reliability.
class IpLanguageDetector {
  /// Timeout duration for API requests.
  final Duration timeout;

  /// Whether to print debug information.
  final bool enable_debug_logs;

  const IpLanguageDetector({
    this.timeout = const Duration(seconds: 5),
    this.enable_debug_logs = false,
  });

  void _log(String message) {
    if (enable_debug_logs) {
      debugPrint('[IpLanguageDetector] $message');
    }
  }

  /// Detects the user's country based on their IP address.
  ///
  /// Tries multiple providers in sequence until one succeeds.
  /// Returns [IpLocationResult] with country information or error details.
  ///
  /// Provider order prioritizes HTTPS endpoints for better platform compatibility:
  /// 1. ipwhois.app (HTTPS)
  /// 2. ipinfo.io (HTTPS)
  /// 3. ip-api.com (HTTP - fallback, may be blocked on some platforms)
  Future<IpLocationResult> detect_country() async {
    // Try HTTPS providers first for better platform compatibility
    final providers = [
      _try_ip_whois, // HTTPS - try first
      _try_ip_info, // HTTPS
      _try_ip_api, // HTTP - fallback (may be blocked on iOS/Android)
    ];

    for (final provider in providers) {
      try {
        final result = await provider();
        if (result.success) {
          _log('Successfully detected location: $result');
          return result;
        }
        _log('Provider failed: ${result.error_message}');
      } catch (e) {
        _log('Provider threw exception: $e');
      }
    }

    return IpLocationResult.failure('All geolocation providers failed');
  }

  /// Provider 1: ip-api.com (free, no API key required, 45 requests/minute limit)
  /// Note: Free tier only supports HTTP. For HTTPS, a paid plan is required.
  /// We use HTTP here as it's acceptable for non-sensitive geolocation data.
  Future<IpLocationResult> _try_ip_api() async {
    _log('Trying ip-api.com...');

    final response = await http
        .get(Uri.parse('http://ip-api.com/json/?fields=status,message,countryCode,country,city'))
        .timeout(timeout);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return IpLocationResult.failure('ip-api.com returned invalid JSON format');
      }
      final data = decoded;

      if (data['status'] == 'success') {
        final country_code = data['countryCode'];
        if (country_code is! String || country_code.isEmpty) {
          return IpLocationResult.failure('ip-api.com returned no country code');
        }
        return IpLocationResult.success(
          country_code: country_code,
          country_name: data['country'] as String?,
          city: data['city'] as String?,
        );
      } else {
        return IpLocationResult.failure(data['message'] as String? ?? 'Unknown error from ip-api.com');
      }
    }

    return IpLocationResult.failure('ip-api.com returned status ${response.statusCode}');
  }

  /// Provider 2: ipwhois.app (free, no API key required, 10000 requests/month)
  Future<IpLocationResult> _try_ip_whois() async {
    _log('Trying ipwhois.app...');

    final response = await http
        .get(Uri.parse('https://ipwhois.app/json/?objects=country_code,country,city,success,message'))
        .timeout(timeout);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return IpLocationResult.failure('ipwhois.app returned invalid JSON format');
      }
      final data = decoded;

      if (data['success'] == true) {
        final country_code = data['country_code'];
        if (country_code is! String || country_code.isEmpty) {
          return IpLocationResult.failure('ipwhois.app returned no country code');
        }
        return IpLocationResult.success(
          country_code: country_code,
          country_name: data['country'] as String?,
          city: data['city'] as String?,
        );
      } else {
        return IpLocationResult.failure(data['message'] as String? ?? 'Unknown error from ipwhois.app');
      }
    }

    return IpLocationResult.failure('ipwhois.app returned status ${response.statusCode}');
  }

  /// Provider 3: ipinfo.io (free tier, 50000 requests/month)
  Future<IpLocationResult> _try_ip_info() async {
    _log('Trying ipinfo.io...');

    final response = await http.get(Uri.parse('https://ipinfo.io/json')).timeout(timeout);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return IpLocationResult.failure('ipinfo.io returned invalid JSON format');
      }
      final data = decoded;

      final country_code = data['country'];
      if (country_code is String && country_code.isNotEmpty) {
        return IpLocationResult.success(
          country_code: country_code,
          country_name: null, // ipinfo.io doesn't return country name in free tier
          city: data['city'] as String?,
        );
      } else {
        return IpLocationResult.failure('ipinfo.io returned no country data');
      }
    }

    return IpLocationResult.failure('ipinfo.io returned status ${response.statusCode}');
  }
}
