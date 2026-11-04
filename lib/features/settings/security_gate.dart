import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/data/providers.dart';
import '../../core/services/security_service.dart';
import '../../core/services/service_providers.dart';

/// This lives in MaterialApp.builder, ABOVE the Navigator, so pushed routes,
/// receipt viewers, and open forms cannot bypass the lock on resume.
class SecurityGate extends ConsumerStatefulWidget {
  final Widget child;
  const SecurityGate({super.key, required this.child});
  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}
class _SecurityGateState extends ConsumerState<SecurityGate> with WidgetsBindingObserver {
  final pin = TextEditingController();
  bool authenticating = false, obscured = false, backgrounded = false;
  int failed = 0;
  DateTime? blockedUntil;
  String message = '';
  Timer? timer;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && ref.read(appProvider).settings.lockMode == 'biometric') _biometric(); }); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); pin.dispose(); timer?.cancel(); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (authenticating) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) setState(() => obscured = true);
    if (state == AppLifecycleState.paused) { backgrounded = true; if (ref.read(appProvider).settings.lockMode != 'none') ref.read(unlockedProvider.notifier).state = false; }
    if (state == AppLifecycleState.resumed) { setState(() => obscured = false); if (backgrounded && ref.read(appProvider).settings.lockMode == 'biometric') _biometric(); backgrounded = false; }
  }
  bool get blocked => blockedUntil != null && blockedUntil!.isAfter(DateTime.now());
  Future<void> _biometric() async {
    if (authenticating || ref.read(unlockedProvider) || blocked) return;
    setState(() => authenticating = true);
    try {
      final okay = await LocalAuthentication().authenticate(localizedReason: 'Unlock your private finance companion', options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true));
      if (okay && mounted) { ref.read(unlockedProvider.notifier).state = true; pin.clear(); }
    } catch (_) { if (mounted) setState(() => message = 'Biometrics unavailable. Use your six-digit PIN.'); }
    if (mounted) setState(() { authenticating = false; obscured = false; });
  }
  Future<void> _pin() async {
    if (authenticating || blocked) return;
    setState(() => authenticating = true);
    final settings = ref.read(appProvider).settings;
    final okay = await SecurityService.verifyPin(pin.text, settings.pinHash, settings.pinSalt);
    if (!mounted) return;
    setState(() => authenticating = false);
    pin.clear();
    if (okay) { failed = 0; message = ''; ref.read(unlockedProvider.notifier).state = true; } else {
      failed++;
      setState(() => message = 'That PIN doesn’t match. Try again.');
      if (failed >= 5) {
        blockedUntil = DateTime.now().add(const Duration(seconds: 30)); failed = 0;
        timer?.cancel(); timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (!mounted) { timer.cancel(); return; } setState(() {}); if (!blocked) timer.cancel(); });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appProvider).settings;
    final locked = settings.lockMode != 'none' && !ref.watch(unlockedProvider);
    return Stack(children: [Offstage(offstage: locked || obscured, child: ExcludeSemantics(excluding: locked || obscured, child: widget.child)), if (locked) Positioned.fill(child: Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Column(children: [Icon(Icons.lock_rounded, size: 48, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 24), Text('A space just for you', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center), const SizedBox(height: 12), const Text('Unlock PaisaClone to continue.'), const SizedBox(height: 32), TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, enabled: !blocked && !authenticating, autofillHints: null, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Six-digit PIN', counterText: ''), onSubmitted: (_) => _pin()), const SizedBox(height: 14), if (message.isNotEmpty) Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)), const SizedBox(height: 20), FilledButton(onPressed: blocked || authenticating ? null : _pin, child: Text(blocked ? 'Wait ${blockedUntil!.difference(DateTime.now()).inSeconds + 1}s' : authenticating ? 'Unlocking…' : 'Unlock')), if (settings.lockMode == 'biometric') TextButton.icon(onPressed: blocked || authenticating ? null : _biometric, icon: const Icon(Icons.fingerprint_rounded), label: const Text('Use biometrics')), const SizedBox(height: 24), const Text('Your PIN protects the app interface, not the underlying database. Forgotten PINs cannot be recovered; restore a backup after reinstalling.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.6))]))))))), if (obscured) const Positioned.fill(child: ColoredBox(color: Color(0xff172212)))]);
  }
}
