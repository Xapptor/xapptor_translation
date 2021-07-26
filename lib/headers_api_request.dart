import 'package:universal_platform/universal_platform.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, String>> headers_api_request() async {
  Map<String, String> headers = {
    "Content-type": "application/json",
  };

  if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
    PackageInfo package_info = await PackageInfo.fromPlatform();
    String package_name = package_info.packageName;
    String build_signature = package_info.buildSignature;
    if (UniversalPlatform.isAndroid) {
      headers["x-android-package"] = package_name;
      headers["x-android-cert"] = build_signature;
    } else if (UniversalPlatform.isIOS) {
      headers["x-ios-bundle-identifier"] = package_name;
    }
  }
  return headers;
}
