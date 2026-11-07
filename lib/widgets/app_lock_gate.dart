import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/paisa_colors.dart';
import '../core/utils/app_lock.dart';
import '../data/models/settings_model.dart';
import '../providers/paisa_provider.dart';
import 'avatar_view.dart';

/// Wraps the whole app and keeps it behind the device lock when the user turned
/// on Settings › Security › App lock.
///
/// * The prompt is `local_auth`'s `authenticate` with `biometricOnly: false`, so
///   the device PIN / pattern / password always works as a fallback.
/// * The app re-locks when it leaves the foreground and comes back — the
///   behaviour people expect from a finance app.
/// * When the platform cannot authenticate at all (no screen lock, unsupported
///   build) the app opens anyway and says why: a broken lock must never destroy
///   access to the user's own ledger.
/// * [authenticator] exists for tests; production always uses the real
///   `local_auth` plugin,
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, this.authenticator});

  /// The unlocked application.
  final Widget child;

  /// Overrides the device-auth implementation. Only tests pass this: the real
  /// gate talks to `local_auth` through `authenticateWithDevice`.
  final DeviceAuthenticator? authenticator;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  String? _error;
  bool _lockOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<PaisaProvider>().biometricEnabled) {
        setState(() => _locked = true);
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (context.read<PaisaProvider>().biometricEnabled) {
        _lockOnResume = true;
      }
      return;
    }
    if (state != AppLifecycleState.resumed || !_lockOnResume) return;
    _lockOnResume = false;
    if (!mounted) return;
    if (!context.read<PaisaProvider>().biometricEnabled) return;
    setState(() {
      _locked = true;
      _error = null;
    });
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });
    final DeviceAuthResult result = await authenticateWithDevice(
      reason: 'Unlock MoneyMate to view your money',
      authenticator: widget.authenticator,
    );
    if (!mounted) return;
    if (result.message != null) {
      // The platform could not even try; open up and explain once.
      setState(() {
        _locked = false;
        _authenticating = false;
        _error = null;
      });
      _notify('${result.message} MoneyMate stayed unlocked this time.');
      return;
    }
    setState(() {
      _authenticating = false;
      _locked = !result.authenticated;
      _error = result.authenticated
          ? null
          : 'Authentication cancelled. Unlock to see your ledger.';
    });
  }

  void _notify(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watching keeps the gate honest: switching the lock off in Settings
    // releases the app on the very next frame.
    final bool enabled = context.watch<PaisaProvider>().biometricEnabled;
    if (!enabled || !_locked) return widget.child;
    return _LockScreen(
      authenticating: _authenticating,
      error: _error,
      onUnlock: _authenticate,
    );
  }
}

/// The lock screen: the user's avatar, the app name and one large unlock button
/// on the theme's tonal gradient.
class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.authenticating,
    required this.error,
    required this.onUnlock,
  });

  final bool authenticating;
  final String? error;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final SettingsModel settings = context.watch<PaisaProvider>().settings;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              scheme.primaryContainer,
              Color.alphaBlend(
                scheme.surface.withAlpha(60),
                scheme.primaryContainer,
              ),
              scheme.surface,
            ],
            stops: const <double>[0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                PaisaAvatarView(
                  avatarIndex: settings.userAvatarIndex,
                  imagePath: settings.customImagePath,
                  size: 96,
                  borderWidth: 3,
                  borderColor: scheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'MoneyMate',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Locked for privacy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                if (error != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.expenseContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: colors.expense,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: authenticating ? null : onUnlock,
                    icon: authenticating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint_rounded),
                    label: Text(
                      authenticating ? 'Waiting for the device…' : 'Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your fingerprint, face or device PIN unlocks MoneyMate. '
                  'Everything stays on this device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
