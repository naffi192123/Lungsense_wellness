import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Page showing user settings, profile variables, and session logging out options.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Header (Profile Card)
                _buildProfileHeader(context),
                const SizedBox(height: 24),

                // Settings Group
                _buildSettingsGroup(
                  context,
                  title: 'SETTINGS & SUPPORT',
                  items: [
                    _SettingsItem(Icons.mail_outline_rounded, 'Contact Us', route: '/contact-us'),
                    _SettingsItem(Icons.lock_outline_rounded, 'Privacy Policy', route: '/privacy-policy'),
                  ],
                ),
                const SizedBox(height: 32),

                // Logout Button
                _buildLogoutButton(context),
                const SizedBox(height: 24),

                // App Version info
                Text(
                  'Version 2.4.0 (Build 452)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String email = 'alex.rivera@wellness.com';
    String displayName = 'Alex Rivera';

    if (authState is AuthAuthenticated) {
      email = authState.user.email;
      displayName = (authState.user.name != null && authState.user.name!.isNotEmpty)
          ? authState.user.name!
          : email.split('@').first;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: const CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.border,
                child: Icon(Icons.person_rounded, size: 54, color: AppColors.primary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.supportingGreen,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.surface),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(item.icon, color: AppColors.secondary, size: 22),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.text),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.border),
                onTap: () {
                  if (item.route != null) {
                    context.push(item.route!);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AuthBloc>().add(const AuthLogoutEvent());
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? route;

  _SettingsItem(this.icon, this.title, {this.route});
}
