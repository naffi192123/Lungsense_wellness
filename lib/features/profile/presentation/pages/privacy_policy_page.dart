import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LungSense Privacy Policy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last updated: July 2026',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('1. Information We Collect'),
              _buildSectionBody(
                'LungSense collects personal wellness information, including basic demographic data (age, gender, height, weight), lifestyle factors, daily symptom check-ins, and acoustic audio recordings (cough and breathing) uploaded for analysis.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. How We Use Your Information'),
              _buildSectionBody(
                'Your data is exclusively used to provide personal respiratory health tracking, acoustic signature analysis simulation, and wellness score calculations. We do not sell your personal data to third parties.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. Audio Recording & Data Protection'),
              _buildSectionBody(
                'Audio recordings uploaded for feature extraction are transmitted securely using encrypted TLS connection protocols. Recordings are stored and processed strictly in accordance with your explicit consent preferences.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Data Retention & Control'),
              _buildSectionBody(
                'You may request the deletion of your account and associated respiratory check-in logs or recordings at any time through our contact and support channels.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text),
    );
  }

  Widget _buildSectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }
}
