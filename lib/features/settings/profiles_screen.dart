import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../onboarding/onboarding_screen.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return FeaturePage(title: 'A space for every side of life', subtitle: 'Completely separate accounts, activity & plans', actions: [IconButton(tooltip: 'Create profile', onPressed: () => openPage(context, const OnboardingScreen(addingProfile: true)), icon: const Icon(Icons.person_add_alt_1_rounded))], child: ListView(children: [for (final data in app.profiles) Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: ListTile(contentPadding: const EdgeInsets.all(18), leading: CircleAvatar(backgroundColor: Color(data.profile.color), foregroundColor: const Color(0xff24341a), child: Text(data.profile.name.characters.first.toUpperCase())), title: Text(data.profile.name), subtitle: AmountText(Ledger(data, app.settings).netWorth, currency: data.profile.currency), selected: data.profile.id == app.activeProfileId, onTap: () => runSafe(context, () => ref.read(appProvider.notifier).switchProfile(data.profile.id), success: 'Switched to ${data.profile.name}'), trailing: PopupMenuButton<String>(onSelected: (action) async { if (action == 'rename') { final value = await askText(context, 'Rename profile', initial: data.profile.name); if (value != null && context.mounted) await runSafe(context, () => ref.read(appProvider.notifier).mutate((app) => app.copyWith(profiles: [for (final profile in app.profiles) if (profile.profile.id == data.profile.id) profile.copyWith(profile: profile.profile.copyWith(name: value)) else profile]))); } else if (await confirm(context, 'Delete ${data.profile.name}?', 'ALL accounts, transactions, receipts and plans in this profile will be removed. Export a full backup first.') && context.mounted) { await runSafe(context, () => ref.read(appProvider.notifier).deleteProfile(data.profile.id)); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('Rename')), PopupMenuItem(value: 'delete', child: Text('Delete profile'))])))), const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => openPage(context, const OnboardingScreen(addingProfile: true)), icon: const Icon(Icons.add_rounded), label: const Text('Create a private profile')), const SizedBox(height: 12), TextButton.icon(onPressed: () => runSafe(context, () => ref.read(appProvider.notifier).createProfile(name: 'Demo', currency: ref.read(profileProvider)!.profile.currency, accountName: 'Everyday', demo: true), success: 'Created a separate demo profile. Your other profiles are untouched.'), icon: const Icon(Icons.explore_outlined), label: const Text('Explore with a separate demo profile')), const SizedBox(height: 100)]));
  }
}
