import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';

import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionTitle(l10n.account),
          _Tile(
            icon: Icons.edit,
            title: l10n.editProfile,
            subtitle: l10n.editProfileSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _Tile(
            icon: Icons.verified,
            title: l10n.publisherJournalistVerification,
            subtitle: l10n.publisherJournalistVerificationSubtitle,
            onTap: () {},
          ),

          const SizedBox(height: 14),
          _SectionTitle(l10n.appSection),
          _Tile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.chooseAppLanguage,
            onTap: () {},
          ),
          _Tile(
            icon: Icons.notifications_none,
            title: l10n.notifications,
            subtitle: l10n.notificationsSubtitle,
            onTap: () {},
          ),

          const SizedBox(height: 14),
          _SectionTitle(l10n.aboutSection),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacy,
            subtitle: l10n.privacySubtitle,
            onTap: () {},
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: l10n.terms,
            subtitle: l10n.termsSubtitle,
            onTap: () {},
          ),
          _Tile(
            icon: Icons.info_outline,
            title: l10n.aboutCarNews,
            subtitle: l10n.aboutCarNewsSubtitle,
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _LogoutTile(ref: ref),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final WidgetRef ref;
  const _LogoutTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text(
          l10n.logout,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          l10n.logoutSubtitle,
          style: const TextStyle(color: Colors.redAccent),
        ),
        onTap: () => _confirmLogout(context),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
