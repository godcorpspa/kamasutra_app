import 'package:easy_localization/easy_localization.dart';

/// Localized message for a FirebaseAuthException code.
///
/// Firebase's own `message` is always English, so it is never shown to the
/// user; unknown codes fall back to a generic text that carries the code.
String authErrorText(String code) {
  switch (code) {
    case 'weak-password':
      return 'auth.error_weak_password'.tr();
    case 'email-already-in-use':
      return 'auth.error_email_in_use'.tr();
    case 'invalid-email':
      return 'auth.error_invalid_email'.tr();
    case 'user-not-found':
      return 'auth.error_user_not_found'.tr();
    case 'wrong-password':
      return 'auth.error_wrong_password'.tr();
    case 'user-disabled':
      return 'auth.error_user_disabled'.tr();
    case 'too-many-requests':
      return 'auth.error_too_many_requests'.tr();
    case 'invalid-credential':
      return 'auth.error_invalid_credential'.tr();
    case 'operation-not-allowed':
      return 'auth.error_not_allowed'.tr();
    case 'network-request-failed':
      return 'auth.error_network'.tr();
    default:
      return 'auth.error_auth_generic'.tr(namedArgs: {'code': code});
  }
}
