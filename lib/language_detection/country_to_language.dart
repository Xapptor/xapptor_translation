/// Maps ISO 3166-1 alpha-2 country codes to their primary language codes (ISO 639-1).
///
/// This mapping prioritizes the most commonly spoken language in each country.
/// For countries with multiple official languages, the most widely used is selected.

const Map<String, String> country_to_language_map = {
  // Americas
  'US': 'en', // United States
  'CA': 'en', // Canada (English majority, French in Quebec)
  'MX': 'es', // Mexico
  'BR': 'pt', // Brazil
  'AR': 'es', // Argentina
  'CO': 'es', // Colombia
  'PE': 'es', // Peru
  'VE': 'es', // Venezuela
  'CL': 'es', // Chile
  'EC': 'es', // Ecuador
  'GT': 'es', // Guatemala
  'CU': 'es', // Cuba
  'BO': 'es', // Bolivia
  'DO': 'es', // Dominican Republic
  'HN': 'es', // Honduras
  'PY': 'es', // Paraguay
  'SV': 'es', // El Salvador
  'NI': 'es', // Nicaragua
  'CR': 'es', // Costa Rica
  'PA': 'es', // Panama
  'UY': 'es', // Uruguay
  'PR': 'es', // Puerto Rico
  'JM': 'en', // Jamaica
  'TT': 'en', // Trinidad and Tobago
  'HT': 'fr', // Haiti

  // Europe
  'GB': 'en', // United Kingdom
  'DE': 'de', // Germany
  'FR': 'fr', // France
  'IT': 'it', // Italy
  'ES': 'es', // Spain
  'PL': 'pl', // Poland
  'RO': 'ro', // Romania
  'NL': 'nl', // Netherlands
  'BE': 'nl', // Belgium (Dutch majority)
  'GR': 'el', // Greece
  'CZ': 'cs', // Czech Republic
  'PT': 'pt', // Portugal
  'SE': 'sv', // Sweden
  'HU': 'hu', // Hungary
  'AT': 'de', // Austria
  'CH': 'de', // Switzerland (German majority)
  'BG': 'bg', // Bulgaria
  'DK': 'da', // Denmark
  'FI': 'fi', // Finland
  'SK': 'sk', // Slovakia
  'NO': 'no', // Norway
  'IE': 'en', // Ireland
  'HR': 'hr', // Croatia
  'MD': 'ro', // Moldova
  'BA': 'bs', // Bosnia and Herzegovina
  'AL': 'sq', // Albania
  'LT': 'lt', // Lithuania
  'MK': 'mk', // North Macedonia
  'SI': 'sl', // Slovenia
  'LV': 'lv', // Latvia
  'EE': 'et', // Estonia
  'CY': 'el', // Cyprus
  'LU': 'fr', // Luxembourg
  'MT': 'mt', // Malta
  'IS': 'is', // Iceland
  'UA': 'uk', // Ukraine
  'BY': 'be', // Belarus
  'RS': 'sr', // Serbia
  'ME': 'sr', // Montenegro

  // Asia
  'CN': 'zh-CN', // China (Simplified Chinese)
  'JP': 'ja', // Japan
  'KR': 'ko', // South Korea
  'IN': 'hi', // India (Hindi, though English is widely used)
  'ID': 'id', // Indonesia
  'PK': 'ur', // Pakistan
  'BD': 'bn', // Bangladesh
  'VN': 'vi', // Vietnam
  'PH': 'fil', // Philippines (Filipino - more widely supported than 'tl')
  'TH': 'th', // Thailand
  'MM': 'my', // Myanmar
  'MY': 'ms', // Malaysia
  'NP': 'ne', // Nepal
  'TW': 'zh-TW', // Taiwan (Traditional Chinese)
  'HK': 'zh-TW', // Hong Kong (Traditional Chinese)
  'SG': 'en', // Singapore
  'KH': 'km', // Cambodia
  'LA': 'lo', // Laos
  'MN': 'mn', // Mongolia
  'KZ': 'kk', // Kazakhstan
  'UZ': 'uz', // Uzbekistan
  'AF': 'ps', // Afghanistan (Pashto)
  'LK': 'si', // Sri Lanka
  'KP': 'ko', // North Korea

  // Middle East
  'TR': 'tr', // Turkey
  'IR': 'fa', // Iran
  'SA': 'ar', // Saudi Arabia
  'IQ': 'ar', // Iraq
  'AE': 'ar', // United Arab Emirates
  'IL': 'he', // Israel
  'JO': 'ar', // Jordan
  'LB': 'ar', // Lebanon
  'KW': 'ar', // Kuwait
  'OM': 'ar', // Oman
  'QA': 'ar', // Qatar
  'BH': 'ar', // Bahrain
  'SY': 'ar', // Syria
  'YE': 'ar', // Yemen
  'PS': 'ar', // Palestine

  // Africa
  'EG': 'ar', // Egypt
  'NG': 'en', // Nigeria
  'ET': 'am', // Ethiopia
  'ZA': 'en', // South Africa
  'KE': 'sw', // Kenya
  'TZ': 'sw', // Tanzania
  'DZ': 'ar', // Algeria
  'SD': 'ar', // Sudan
  'MA': 'ar', // Morocco
  'UG': 'en', // Uganda
  'GH': 'en', // Ghana
  'MZ': 'pt', // Mozambique
  'AO': 'pt', // Angola
  'CI': 'fr', // Ivory Coast
  'CM': 'fr', // Cameroon
  'NE': 'fr', // Niger
  'BF': 'fr', // Burkina Faso
  'ML': 'fr', // Mali
  'MW': 'en', // Malawi
  'ZM': 'en', // Zambia
  'SN': 'fr', // Senegal
  'ZW': 'en', // Zimbabwe
  'RW': 'rw', // Rwanda
  'TN': 'ar', // Tunisia
  'LY': 'ar', // Libya

  // Oceania
  'AU': 'en', // Australia
  'NZ': 'en', // New Zealand
  'PG': 'en', // Papua New Guinea
  'FJ': 'en', // Fiji

  // Russia and Central Asia
  'RU': 'ru', // Russia
  'GE': 'ka', // Georgia
  'AM': 'hy', // Armenia
  'AZ': 'az', // Azerbaijan
  'KG': 'ky', // Kyrgyzstan
  'TJ': 'tg', // Tajikistan
  'TM': 'tk', // Turkmenistan
};

/// Returns the recommended language code for a given country code.
///
/// [country_code] - ISO 3166-1 alpha-2 country code (e.g., 'US', 'MX', 'DE')
/// [default_language] - Fallback language if country is not in the map (default: 'en')
///
/// Returns the ISO 639-1 language code (e.g., 'en', 'es', 'de')
String get_language_from_country(String country_code, {String default_language = 'en'}) {
  final normalized_code = country_code.toUpperCase().trim();
  return country_to_language_map[normalized_code] ?? default_language;
}

/// Returns a list of all supported country codes.
List<String> get_supported_countries() {
  return country_to_language_map.keys.toList();
}

/// Returns a list of all unique language codes in the mapping.
List<String> get_supported_languages() {
  return country_to_language_map.values.toSet().toList();
}
