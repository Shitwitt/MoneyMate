import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:confetti/confetti.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/data/achievements.dart';
import 'core/data/local_store.dart';
import 'core/data/providers.dart';
import 'core/models/models.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/file_service.dart';
import 'core/services/service_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/money.dart';
import 'features/home/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/backup_screen.dart';
import 'features/settings/security_gate.dart';
import 'features/transactions/transaction_form.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/actions.dart';
import 'shared/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  LicenseRegistry.addLicense(() async* { final license = await rootBundle.loadString('assets/fonts/OFL.txt'); yield LicenseEntryWithLineBreaks(['Noto fonts'], license); });
  runApp(const Bootstrap());
}
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}
class _BootstrapState extends State<Bootstrap> {
  late Future<LocalStore> future = LocalStore.open();
  void reload({bool previous = false}) => setState(() => future = LocalStore.open(recoverPrevious: previous));
  @override
  Widget build(BuildContext context) => FutureBuilder<LocalStore>(future: future, builder: (context, snapshot) {
    if (snapshot.hasData) return ProviderScope(overrides: [repositoryProvider.overrideWithValue(snapshot.data!)], child: const PaisaApp());
    return MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(const AppSettings(), Brightness.light), home: snapshot.hasError ? Scaffold(appBar: AppBar(title: const Text('Your data needs a little care')), body: Builder(builder: (context) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: Column(children: [const Icon(Icons.health_and_safety_outlined, size: 56), const SizedBox(height: 20), const Text('We won’t overwrite a file we can’t read.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22), textAlign: TextAlign.center), const SizedBox(height: 16), Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 24), FilledButton(onPressed: () => reload(), child: const Text('Try again')), TextButton(onPressed: () => reload(previous: true), child: const Text('Recover the previous local snapshot')), TextButton(onPressed: () => restoreBackup(context, (preview) async { final store = LocalStore(Hive.box<String>('paisaclone_v1'), const AppData()); final data = preview.data.copyWith(settings: preview.data.settings.copyWith(lockMode: 'none', pinHash: '', pinSalt: '', allowSilentAdds: false, notificationsEnabled: false)); await store.save(data); if (mounted) reload(); }), child: const Text('Restore a verified backup')), TextButton(onPressed: () => runSafe(context, () async { if (!Hive.isBoxOpen('paisaclone_v1')) throw const FormatException('Storage is not accessible. Check device permissions and free space.'); await FileService.save(Uint8List.fromList(utf8.encode(Hive.box<String>('paisaclone_v1').get('state') ?? '')), 'PaisaClone-raw-recovery.json', mime: 'application/json'); }), child: const Text('Export raw recovery data')), const SizedBox(height: 12), const Text('Raw recovery data is sensitive, unencrypted, and is not a standard backup. Keep it private. Never clear app data before securing a copy.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.6))])))))) : const Scaffold(body: LoadingSkeleton()));
  });
}
class PaisaApp extends ConsumerStatefulWidget {
  final bool enablePlatformServices;
  const PaisaApp({super.key, this.enablePlatformServices = true});
  @override
  ConsumerState<PaisaApp> createState() => _PaisaAppState();
}
class _PaisaAppState extends ConsumerState<PaisaApp> with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? links;
  final pending = <Uri>[];
  bool processing = false;
  String? lastLink;
  DateTime? lastLinkAt;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    if (widget.enablePlatformServices) WidgetsBinding.instance.addPostFrameCallback((_) => _initRuntime());
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); links?.cancel(); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enablePlatformServices && ref.read(profileProvider) != null) {
      unawaited(_catchUp());
      _drainLinks();
    }
  }
  Future<void> _catchUp() async {
    try { await ref.read(appProvider.notifier).processRecurring(); } catch (error) { final context = navigator.currentContext; if (context != null && context.mounted) toast(context, 'Recurring catch-up could not be saved. Check free storage and try again.'); }
  }
  Future<void> _initRuntime() async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    if (!mounted) return;
    await _sync(ref.read(appProvider));
    if (ref.read(profileProvider) != null) await _catchUp();
    if (!mounted) return;
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (!mounted) return;
      if (initial != null) _acceptLink(initial);
      links = appLinks.uriLinkStream.listen(_acceptLink, onError: (Object error) { final context = navigator.currentContext; if (context != null && context.mounted) toast(context, 'This link could not be opened.'); });
      if (kIsWeb && Uri.base.queryParameters.containsKey('amount')) _acceptLink(Uri(scheme: 'https', host: Uri.base.host, path: '/add', query: Uri.base.query));
    } catch (_) { /* Deep links are optional on unsupported platforms. */ }
  }
  Future<void> _sync(AppData app) async {
    if (!widget.enablePlatformServices) return;
    await Future.wait([ref.read(widgetServiceProvider).sync(app), ref.read(notificationServiceProvider).sync(app, (marks) => ref.read(appProvider.notifier).markNotifications(marks))]);
  }
  void _acceptLink(Uri uri) {
    final now = DateTime.now();
    if (lastLink == uri.toString() && lastLinkAt != null && now.difference(lastLinkAt!) < const Duration(seconds: 2)) return;
    lastLink = uri.toString(); lastLinkAt = now;
    if (pending.length >= 10) return;
    pending.add(uri); _drainLinks();
  }
  void _drainLinks() {
    if (processing || !mounted || ref.read(profileProvider) == null || !ref.read(unlockedProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || processing) return;
      processing = true;
      try {
        while (pending.isNotEmpty && mounted && ref.read(profileProvider) != null && ref.read(unlockedProvider)) {
          final context = navigator.currentContext;
          if (context == null || !context.mounted) break;
          final uri = pending.removeAt(0);
          if (uri.scheme == 'paisa' && uri.host == 'home') continue;
          await runSafe(context, () async {
            final profile = ref.read(profileProvider)!;
            final request = DeepLinkService.parse(uri, profile);
            if (request.transaction == null) { await openPage(context, const TransactionForm()); return; }
            final transaction = request.transaction!;
            final settings = ref.read(appProvider).settings;
            final account = profile.accounts.firstWhere((item) => item.id == transaction.accountId);
            final approved = request.silent && settings.allowSilentAdds || await confirm(context, 'Add this ${transaction.type}?', '${transaction.name}\n${money(transaction.amountMinor, account.currency, hidden: settings.hideAmounts)} · ${account.name}\n\nThis request came from an external link. Confirm only if you recognize it.', confirmLabel: 'Add transaction');
            if (!approved) return;
            if (ref.read(appProvider).activeProfileId != profile.profile.id) throw const FormatException('Profile changed. Open the link again in the intended profile.');
            await ref.read(appProvider.notifier).saveTransaction(transaction);
            if (context.mounted) toast(context, 'Transaction saved privately on your device');
          });
        }
      } finally { processing = false; }
    });
  }
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    ref.listen<AppData>(appProvider, (previous, next) {
      unawaited(_sync(next));
      if (previous?.activeProfileId != next.activeProfileId || previous?.profiles.isEmpty == true) { if (next.profiles.isNotEmpty && widget.enablePlatformServices) unawaited(_catchUp()); }
      _drainLinks();
      if (previous != null && previous.activeProfileId == next.activeProfileId && ref.read(unlockedProvider)) {
        final old = previous.profiles.where((item) => item.profile.id == previous.activeProfileId).firstOrNull?.achievements.map((item) => item.id).toSet() ?? <String>{};
        final fresh = next.profiles.where((item) => item.profile.id == next.activeProfileId).firstOrNull?.achievements.where((item) => !old.contains(item.id)).toList() ?? <Achievement>[];
        if (fresh.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) { final context = navigator.currentContext; if (context != null && context.mounted && ref.read(unlockedProvider)) showDialog<void>(context: context, builder: (_) => _Celebration(badges.firstWhere((badge) => badge.id == fresh.first.id).name)); });
      }
    });
    ref.listen<bool>(unlockedProvider, (previous, next) { if (next) _drainLinks(); });
    Widget material(ColorScheme? light, ColorScheme? dark) => MaterialApp(
      navigatorKey: navigator, debugShowCheckedModeBanner: false, title: 'PaisaClone',
      theme: buildTheme(app.settings, Brightness.light, dynamicScheme: light), darkTheme: buildTheme(app.settings, Brightness.dark, dynamicScheme: dark),
      themeMode: switch (app.settings.theme) {'light' => ThemeMode.light, 'dark' || 'black' => ThemeMode.dark, _ => ThemeMode.system},
      locale: Locale(app.settings.locale), supportedLocales: AppLocalizations.supportedLocales, localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1) * app.settings.fontScale)), child: SecurityGate(child: child ?? const SizedBox.shrink())),
      home: app.profiles.isEmpty ? const OnboardingScreen() : AppShell(key: ValueKey(app.activeProfileId)),
    );
    if (!widget.enablePlatformServices) return material(null, null);
    return DynamicColorBuilder(builder: material);
  }
}
class _Celebration extends StatefulWidget {
  final String name;
  const _Celebration(this.name);
  @override
  State<_Celebration> createState() => _CelebrationState();
}
class _CelebrationState extends State<_Celebration> {
  final confetti = ConfettiController(duration: const Duration(seconds: 2));
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && !MediaQuery.disableAnimationsOf(context)) confetti.play(); }); }
  @override
  void dispose() { confetti.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(content: Stack(alignment: Alignment.topCenter, children: [Padding(padding: const EdgeInsets.only(top: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium_rounded, size: 68, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 20), Text('A little win!', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12), Text(widget.name, textAlign: TextAlign.center), const SizedBox(height: 8), const Text('Progress, not perfection. You’re doing beautifully.', textAlign: TextAlign.center, style: TextStyle(height: 1.6))])), ConfettiWidget(confettiController: confetti, blastDirectionality: BlastDirectionality.explosive, emissionFrequency: .04, numberOfParticles: 14, gravity: .2)]), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('A little proud of myself'))]);
}
