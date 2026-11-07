import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// The outcome of a device-credential prompt.
class DeviceAuthResult {
  const DeviceAuthResult({
    required this.authenticated,
    this.message,
  });

  /// True when the device confirmed the user.
  final bool authenticated;

  /// Why authentication did not happen, in words a user can act on. `null` when
  /// the prompt succeeded or was cancelled by the user.
  final String? message;
}

/// Signature of [authenticateWithDevice], so widgets can accept a stand-in.
typedef DeviceAuthenticator = Future<DeviceAuthResult> Function({
  required String reason,
});

/// Prompts for the device's biometric / PIN / pattern lock.
///
/// [biometricOnly] is left `false` on purpose: finance apps must not become
/// unopenable because a fingerprint reader is wet or no fingerprint is enrolled
/// while a perfectly good device PIN exists.
Future<DeviceAuthResult> authenticateWithDevice({
  required String reason,
  DeviceAuthenticator? authenticator,
}) async {
  if (authenticator != null) return authenticator(reason: reason);

  final LocalAuthentication auth = LocalAuthentication();
  try {
    final bool supported = await auth.isDeviceSupported();
    if (!supported) {
      return const DeviceAuthResult(
        authenticated: true,
        message: 'No screen lock is set up on this device.',
      );
    }
    final bool ok = await auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
    return DeviceAuthResult(authenticated: ok);
  } on PlatformException catch (error) {
    return DeviceAuthResult(
      authenticated: true,
      message: error.message ?? 'The screen lock could not be read.',
    );
  } on MissingPluginException {
    return const DeviceAuthResult(
      authenticated: true,
      message: 'App lock is not available on this platform build.',
    );
  } catch (error) {
    return DeviceAuthResult(authenticated: true, message: error.toString());
  }
}

/// Convenience wrapper for the settings toggle: returns `true` only when the
/// device actually confirmed the user.
Future<bool> requestDeviceUnlock({
  required String reason,
  DeviceAuthenticator? authenticator,
}) async {
  final DeviceAuthResult result = await authenticateWithDevice(
    reason: reason,
    authenticator: authenticator,
  );
  return result.authenticated;
}
