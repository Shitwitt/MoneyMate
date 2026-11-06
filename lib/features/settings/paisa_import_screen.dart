// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/services/file_service.dart';
import '../../core/services/paisa_import_service.dart';
import '../../core/services/paisa_legacy_decoder.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class PaisaImportScreen extends ConsumerStatefulWidget {
  final Uint8List? initialBytes;
  const PaisaImportScreen({super.key, this.initialBytes});
  @override
  ConsumerState<PaisaImportScreen> createState() => _PaisaImportScreenState();
}

class _PaisaImportScreenState extends ConsumerState<PaisaImportScreen> {
  final _name = TextEditingController(text: 'Paisa import');
  final _scroll = ScrollController();
  Uint8List? _bytes;
  Paisa636Data? _document;
  PaisaImportPreview? _preview;
  String _filename = '', _currency = '';
  String? _error;
  LegacyDebtMapping? _debtMapping;
  bool _keepOriginal = true, _busy = false, _saved = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_invalidate);
    if (widget.initialBytes != null) {
      _bytes = Uint8List.fromList(widget.initialBytes!);
      _filename = 'Paisa-6.3.6.json';
      try {
        _document = PaisaImportService.decode(_bytes!);
      } catch (_) {
        _error = 'This is not a supported Paisa 6.3.6 JSON export.';
        _bytes = null;
      }
    }
  }

  void _invalidate() {
    if (mounted)
      setState(() {
        _preview = null;
        _error = null;
      });
  }

  @override
  void dispose() {
    _name.removeListener(_invalidate);
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_busy || _saved) return;
    setState(() => _busy = true);
    await runSafe(context, () async {
      final file = await FileService.pick(['json']);
      if (file == null) return;
      final bytes = Uint8List.fromList(file.bytes);
      final document = PaisaImportService.decode(bytes);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _document = document;
        _filename = file.name;
        _preview = null;
        _error = null;
        _debtMapping = null;
      });
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _validate() async {
    if (_busy || _saved || _bytes == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _preview = null;
      _error = null;
    });
    await runSafe(context, () async {
      try {
        final preview = PaisaImportService.inspect(
          _bytes!,
          name: _name.text,
          currency: _currency,
          debtMapping: _debtMapping,
          keepOriginal: _keepOriginal,
        );
        if (mounted) setState(() => _preview = preview);
      } catch (error) {
        if (mounted)
          setState(
            () =>
                _error = error.toString().replaceFirst('FormatException: ', ''),
          );
        rethrow;
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final preview = _preview;
    if (_busy || _saved || preview == null) return;
    final demo = ref.read(appProvider).isDemo;
    final approved = await confirm(
      context,
      'Create a separate imported profile?',
      '${demo ? 'DEMO MODE: this import is temporary and is discarded on Exit Demo. Exit Demo before importing for real.\n\n' : ''}${preview.profile.accounts.length} accounts and ${preview.profile.transactions.length} transactions will be saved in “${preview.profile.profile.name}”.\n\nNo existing profile is replaced. The app lock is retained. Silent link posting and notifications are switched off for review. You can switch back to your previous profile at any time.\n\nConfirm only after checking the currency, loan directions, rounding and import notes below.',
      confirmLabel: 'Create new profile',
    );
    if (!approved || !mounted) return;
    setState(() => _busy = true);
    final saved = await runSafe(
      context,
      () => ref.read(appProvider.notifier).importLegacyProfile(preview.profile),
    );
    if (!mounted) return;
    // Stay on our own page: an achievement may be presented above it after save.
    // Never pop whichever route happens to be on top of the navigator.
    setState(() {
      _busy = false;
      _saved = saved;
    });
    if (saved)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final duration = referenceMotion(context, 250);
        if (duration == Duration.zero) {
          _scroll.jumpTo(0);
        } else {
          _scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final profile = preview?.profile;
    final needsMapping = _document?.debts.any((v) => v.type != 'goal') ?? false;
    return FeaturePage(
      title: 'Import older Paisa data',
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SectionHeader('Keep your history. Keep your current profiles.'),
          const Text(
            'For the verified, GPL-licensed Paisa 6.3.6 JSON format only. This is not a current Paisa 2026 backup importer. Everything is validated and previewed locally before a separate profile is created.',
          ),
          const SizedBox(height: 16),
          if (ref.watch(appProvider).isDemo)
            const Card(
              child: ListTile(
                leading: Icon(Icons.science_outlined),
                title: Text('Demo mode · temporary import'),
                subtitle: Text(
                  'Exit Demo before importing real data. A profile imported here disappears when you exit the isolated demo.',
                ),
              ),
            ),
          if (_saved)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline_rounded),
                title: Text('Your new profile is saved'),
                subtitle: Text(
                  'Existing profiles are unchanged. Use Back, then Profiles to switch between them. Export a fresh Tink backup after reviewing your imported history.',
                ),
              ),
            ),
          if (!_saved) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(
                _filename.isEmpty
                    ? 'Choose legacy JSON · up to 10 MiB'
                    : _filename,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'New profile name'),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: _busy,
              child: formSelect(
                'Original backup currency (required)',
                _currency,
                ['', ...currencySymbols.keys],
                (value) => setState(() {
                  _currency = value;
                  _preview = null;
                  _error = null;
                }),
                display: (value) => value.isEmpty
                    ? 'Choose the currency used in Paisa'
                    : '$value · ${currencySymbols[value]}',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                'The old export stored amounts, but no per-account currency. Do not guess. All imported accounts will use this one currency.',
              ),
            ),
            if (needsMapping) ...[
              IgnorePointer(
                ignoring: _busy,
                child: formSelect(
                  'Review legacy loan directions',
                  _debtMapping?.name ?? '',
                  ['', ...LegacyDebtMapping.values.map((v) => v.name)],
                  (value) => setState(() {
                    _debtMapping = LegacyDebtMapping.values
                        .where((v) => v.name == value)
                        .firstOrNull;
                    _preview = null;
                    _error = null;
                  }),
                  display: (value) => switch (value) {
                    'debitIsBorrowed' => 'Debt = I borrowed · Credit = I lent',
                    'debitIsLent' => 'Debt = I lent · Credit = I borrowed',
                    _ => 'Confirm what Debt / Credit meant in your records',
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Retain the original JSON with this profile'),
              subtitle: const Text(
                'Keeps original metadata and icon codes downloadable from Backup. It also becomes part of your unencrypted Tink backups.',
              ),
              value: _keepOriginal,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _keepOriginal = value;
                      _preview = null;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed:
                  _busy ||
                      _bytes == null ||
                      _currency.isEmpty ||
                      _name.text.trim().isEmpty ||
                      needsMapping && _debtMapping == null
                  ? null
                  : _validate,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate & preview import'),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (profile != null && preview != null) ...[
            const SizedBox(height: 24),
            const SectionHeader('Validated preview'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      profile.profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${profile.accounts.length} accounts · ${profile.transactions.length} transactions',
                    ),
                    Text(
                      '${preview.sourceCategories} original categories · ${profile.categories.length} Tink categories',
                    ),
                    Text(
                      '${profile.loans.length} loans · ${profile.goals.length} goals · ${preview.repayments} history records',
                    ),
                    const SizedBox(height: 12),
                    const Text('Opening balances · all imported accounts'),
                    AmountText(
                      profile.accounts.fold<int>(
                        0,
                        (sum, account) => sum + account.openingMinor,
                      ),
                      currency: profile.profile.currency,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            for (final loan in profile.loans.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${loan.direction == 'lent' ? 'I lent' : 'I borrowed'} · ${loan.personName}',
                ),
                subtitle: Text(
                  '${loan.repayments.length} repayments · ${loan.completed ? 'manually closed' : 'open'}',
                ),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AmountText(
                      loan.principalMinor,
                      currency: profile.profile.currency,
                    ),
                  ),
                ),
              ),
            if (profile.loans.length > 8)
              Text(
                '${profile.loans.length - 8} more loans will be imported. Review them after switching profiles.',
              ),
            const SizedBox(height: 16),
            const SectionHeader('Read before importing'),
            for (final warning in preview.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('• $warning'),
              ),
            const SizedBox(height: 12),
            if (!_saved)
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Create imported profile'),
              ),
          ],
        ],
      ),
    );
  }
}
