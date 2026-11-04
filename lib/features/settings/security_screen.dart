import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/data/providers.dart';
import '../../core/services/security_service.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});
  Future<void> _setPin(
    BuildContext context,
    WidgetRef ref, {
    bool biometric = false,
  }) async {
    if (biometric && kIsWeb) {
      toast(context, 'Biometrics need the Android or iOS app. Use a PIN here.');
      return;
    }
    if (biometric) {
      final auth = LocalAuthentication();
      try {
        if (!await auth.canCheckBiometrics ||
            (await auth.getAvailableBiometrics()).isEmpty) {
          if (context.mounted) {
            toast(
              context,
              'Set up a fingerprint or face in your device settings first.',
            );
          }
          return;
        }
      } catch (_) {
        if (context.mounted) {
          toast(
            context,
            'This device does not expose biometric authentication.',
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    final pin = TextEditingController(), repeat = TextEditingController();
    await showEditor(
      context,
      title: biometric ? 'Biometrics + a backup PIN' : 'A key just for you',
      description:
          'Choose a six-digit PIN. It is salted and derived with PBKDF2; the PIN itself is never stored. Remember it: there is no server recovery.',
      fields: (_, __) => [
        TextFormField(
          controller: pin,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Six-digit PIN'),
          validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
              ? null
              : 'Exactly six digits',
        ),
        TextFormField(
          controller: repeat,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Repeat PIN'),
          validator: (value) => value == pin.text ? null : 'PINs do not match',
        ),
      ],
      onSave: () async {
        final pair = await SecurityService.createPin(pin.text);
        await ref
            .read(appProvider.notifier)
            .settings(
              (s) => s.copyWith(
                pinHash: pair.$1,
                pinSalt: pair.$2,
                lockMode: biometric ? 'biometric' : 'pin',
              ),
            );
      },
    );
    pin.dispose();
    repeat.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    return FeaturePage(
      title: 'A space just for you',
      child: ListView(
        children: [
          Card(
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 32),
                  SizedBox(height: 16),
                  Text(
                    'No accounts. No trackers. No cloud.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your financial data stays in this app’s local storage. Exporting or sharing is always your choice. The Android release has no Internet permission.',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('App lock'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('Six-digit PIN'),
                  subtitle: Text(
                    settings.lockMode == 'pin'
                        ? 'Enabled'
                        : 'Protect the app on launch and resume',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _setPin(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Fingerprint / Face ID'),
                  subtitle: Text(
                    settings.lockMode == 'biometric'
                        ? 'Enabled · PIN fallback available'
                        : 'Biometrics with a backup PIN',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _setPin(context, ref, biometric: true),
                ),
                if (settings.lockMode != 'none')
                  ListTile(
                    leading: const Icon(Icons.lock_open_rounded),
                    title: const Text('Turn off app lock'),
                    onTap: () async {
                      final entered = await askText(
                        context,
                        'Confirm your current PIN',
                        label: 'Six-digit PIN',
                        numeric: true,
                        obscure: true,
                      );
                      if (entered == null || !context.mounted) return;
                      await runSafe(context, () async {
                        if (!await SecurityService.verifyPin(
                          entered,
                          settings.pinHash,
                          settings.pinSalt,
                        )) {
                          throw const FormatException(
                            'That PIN does not match',
                          );
                        }
                        await ref
                            .read(appProvider.notifier)
                            .settings(
                              (s) => s.copyWith(
                                lockMode: 'none',
                                pinHash: '',
                                pinSalt: '',
                              ),
                            );
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Hide amounts'),
              subtitle: const Text(
                'Replace amounts with dots and hide chart values',
              ),
              secondary: const Icon(Icons.visibility_off_outlined),
              value: settings.hideAmounts,
              onChanged: (value) => runSafe(
                context,
                () => ref
                    .read(appProvider.notifier)
                    .settings((s) => s.copyWith(hideAmounts: value)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Important: this is an interface lock, not at-rest database encryption. A rooted/jailbroken device, browser extensions, or access to your app storage can expose data. Backups are unencrypted. Use device encryption and keep exports private. Widgets hide amounts whenever app lock is enabled.',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
