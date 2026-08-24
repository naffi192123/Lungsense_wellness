import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Use'),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.secondary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            color: AppColors.surface,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LungSense Wellness',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Terms of Use',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Powered by DigiBiomics Inc.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text(
                          'Last Updated: June 16, 2026',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '•   Version 1.0',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Medical Disclaimer Highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.supportingGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.supportingGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.health_and_safety_outlined, color: AppColors.supportingGreen, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LungSense Wellness is a wellness and self-monitoring application. It does not provide medical diagnosis, disease detection, medical screening, treatment, or emergency medical services. In an emergency, contact your local emergency services.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.text,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1
              _buildSection(
                number: '1',
                title: 'Acceptance of Terms',
                content:
                    'These Terms of Use ("Terms") govern your access to and use of the LungSense Wellness mobile application, web application, APIs, and related services (collectively, the "Service") operated by DigiBiomics Inc. ("DigiBiomics", "we", "us", or "our").\n\n'
                    'By creating an account, accessing, downloading, installing, or using LungSense Wellness, you acknowledge that you have read, understood, and agree to be bound by these Terms and the LungSense Wellness Privacy Policy.\n\n'
                    'If you do not agree to these Terms, you must not access or use the Service.',
              ),

              // Section 2
              _buildSection(
                number: '2',
                title: 'About LungSense Wellness',
                content:
                    'LungSense Wellness is a respiratory wellness and self-monitoring application designed to help users track respiratory wellness, record cough and breathing sounds, complete wellness check-ins, monitor personal trends, maintain wellness history, and receive general wellness recommendations.\n\n'
                    'LungSense Wellness is intended for general wellness and self-monitoring purposes. It is not a medical diagnostic service.\n\n'
                    'LungSense Wellness does not provide medical diagnosis, disease detection, medical screening, treatment, medication recommendations, or emergency medical services.',
              ),

              // Section 3
              _buildSection(
                number: '3',
                title: 'Not Medical Advice',
                content:
                    'Information provided through LungSense Wellness is for general wellness and informational purposes only.\n\n'
                    'Wellness scores, symptom information, respiratory recordings, trends, and recommendations should not be interpreted as a medical diagnosis or as confirmation that you do or do not have a medical condition.\n\n'
                    'LungSense Wellness does not replace a qualified healthcare professional.\n\n'
                    'If you have a health concern, persistent symptoms, or believe you require medical attention, consult an appropriately qualified healthcare professional.\n\n'
                    'In an emergency, contact your local emergency services rather than relying on LungSense Wellness.',
              ),

              // Section 4
              _buildSection(
                number: '4',
                title: 'Eligibility',
                content:
                    'You must provide accurate information when creating and maintaining your account.\n\n'
                    'LungSense Wellness is not directed at children under 13. We do not knowingly permit the collection of personal information from children under 13 without appropriate parental or guardian consent.\n\n'
                    'Users between 13 and 17 may use the Service where appropriate parental, guardian, or authorized representative consent has been obtained, as required by applicable law.\n\n'
                    'If you use LungSense Wellness on behalf of another person, you represent that you have the necessary authorization to do so.',
              ),

              // Section 5
              _buildSection(
                number: '5',
                title: 'Account Registration and Security',
                content:
                    'Certain features require an account. You are responsible for providing accurate and current account information and for maintaining the confidentiality of your login credentials.\n\n'
                    '• Keep your account credentials confidential.\n'
                    '• Do not share your account with unauthorized individuals.\n'
                    '• Use reasonable measures to protect the device used to access your account.\n'
                    '• Notify DigiBiomics promptly if you suspect unauthorized access to your account.\n\n'
                    'You are responsible for activities conducted through your account to the extent permitted by applicable law.',
              ),

              // Section 6
              _buildSection(
                number: '6',
                title: 'Permitted Use',
                content:
                    'You may use LungSense Wellness for your personal wellness and self-monitoring purposes and only in accordance with these Terms and applicable law.\n\n'
                    'You must not:\n'
                    '• Use the Service for unlawful, fraudulent, abusive, or harmful purposes.\n'
                    '• Attempt to gain unauthorized access to the Service or its systems.\n'
                    '• Interfere with the operation, availability, or security of the Service.\n'
                    '• Reverse engineer, decompile, or disassemble the Service except where expressly permitted by applicable law.\n'
                    '• Copy, reproduce, modify, distribute, or commercially exploit the Service without authorization.\n'
                    '• Upload malicious code, viruses, or other harmful material.\n'
                    '• Submit another person\'s information without appropriate authorization.\n'
                    '• Use the Service in a manner that infringes the rights of another person.',
              ),

              // Section 7
              _buildSection(
                number: '7',
                title: 'Wellness Information and Recordings',
                content:
                    'Depending on the features you use, LungSense Wellness may allow you to enter wellness information and record cough or breathing sounds.\n\n'
                    'You are responsible for ensuring that information you submit is accurate to the extent reasonably possible and that you have the right and appropriate consent to submit information relating to another person.\n\n'
                    'The collection, processing, storage, retention, and sharing of personal and wellness information are described in the LungSense Wellness Privacy Policy.',
              ),

              // Section 8
              _buildSection(
                number: '8',
                title: 'Wellness Scores and Recommendations',
                content:
                    'LungSense Wellness may calculate wellness scores and provide general wellness recommendations based on information you provide and other information processed by the Service.\n\n'
                    'These scores and recommendations are intended to support wellness awareness and self-monitoring. They are not medical diagnoses, medical screening results, treatment plans, or medical advice.\n\n'
                    'Wellness scores may change as information is updated or as the Service is modified.',
              ),

              // Section 9
              _buildSection(
                number: '9',
                title: 'User Content',
                content:
                    'You retain your rights in information and content that you submit to LungSense Wellness, subject to the permissions necessary for DigiBiomics to operate the Service.\n\n'
                    'By submitting information, you authorize DigiBiomics to process it as necessary to provide the Service, generate requested wellness information, maintain and improve the platform, and perform other activities described in the Privacy Policy.\n\n'
                    'DigiBiomics may use appropriately de-identified or aggregated information for research, validation, statistical analysis, and product improvement, subject to applicable law and the Privacy Policy.',
              ),

              // Section 10
              _buildSection(
                number: '10',
                title: 'Research and De-Identified Information',
                content:
                    'DigiBiomics may use de-identified or aggregated information for scientific research, wellness research, validation studies, academic publications, statistical analysis, and development or improvement of the Service.\n\n'
                    'DigiBiomics will not knowingly publish identifiable personal information without appropriate legal authorization and consent where required.',
              ),

              // Section 11
              _buildSection(
                number: '11',
                title: 'Third-Party Services',
                content:
                    'LungSense Wellness may use third-party service providers for cloud hosting, storage, application infrastructure, analytics, security, email, notifications, and other services necessary to operate the platform.\n\n'
                    'Third-party services may be subject to their own terms and privacy policies. DigiBiomics is not responsible for third-party services that it does not control, except as required by applicable law.',
              ),

              // Section 12
              _buildSection(
                number: '12',
                title: 'Intellectual Property',
                content:
                    'The LungSense Wellness Service, including its software, user interface, design, trademarks, logos, documentation, content, and other proprietary materials, is owned by or licensed to DigiBiomics Inc. and protected by applicable intellectual property laws.\n\n'
                    'These Terms do not transfer ownership of DigiBiomics intellectual property to you.\n\n'
                    'You may not use DigiBiomics or LungSense branding without prior written authorization.',
              ),

              // Section 13
              _buildSection(
                number: '13',
                title: 'Service Availability',
                content:
                    'We will make reasonable efforts to maintain the availability of LungSense Wellness. However, the Service may be unavailable or interrupted because of maintenance, updates, technical failures, network problems, security incidents, third-party service interruptions, or circumstances beyond our reasonable control.\n\n'
                    'We do not guarantee that the Service will always be uninterrupted, error-free, secure, or compatible with every device.',
              ),

              // Section 14
              _buildSection(
                number: '14',
                title: 'Updates and Changes to the Service',
                content:
                    'DigiBiomics may update, modify, suspend, or discontinue features of LungSense Wellness from time to time.\n\n'
                    'Updates may include changes to functionality, security, scoring methods, user interface, and application features.\n\n'
                    'Some updates may be necessary for continued use of the Service.',
              ),

              // Section 15
              _buildSection(
                number: '15',
                title: 'Privacy',
                content:
                    'Your use of LungSense Wellness is also governed by the LungSense Wellness Privacy Policy.\n\n'
                    'The Privacy Policy explains how DigiBiomics collects, uses, stores, shares, protects, and retains personal information.\n\n'
                    'The Privacy Policy forms part of these Terms.',
              ),

              // Section 16
              _buildSection(
                number: '16',
                title: 'User Responsibilities',
                content:
                    'You are responsible for using LungSense Wellness appropriately and for providing information that is accurate to the extent reasonably possible.\n\n'
                    '• Maintain the security of your account.\n'
                    '• Use the Service only for lawful purposes.\n'
                    '• Obtain appropriate authorization before submitting information belonging to another person.\n'
                    '• Follow applicable laws and regulations.\n'
                    '• Seek professional medical assistance when appropriate rather than relying solely on the Service.',
              ),

              // Section 17
              _buildSection(
                number: '17',
                title: 'Suspension and Termination',
                content:
                    'DigiBiomics may suspend or terminate access to LungSense Wellness where reasonably necessary, including where you materially violate these Terms, misuse the Service, create a security or legal risk, or where continued operation is prohibited by applicable law.\n\n'
                    'You may stop using LungSense Wellness at any time.\n\n'
                    'Where applicable, you may request deletion of personal information in accordance with the Privacy Policy.\n\n'
                    'Termination does not eliminate rights or obligations that arose before termination.',
              ),

              // Section 18
              _buildSection(
                number: '18',
                title: 'Disclaimers',
                content:
                    'To the maximum extent permitted by applicable law, LungSense Wellness is provided on an "as available" and "as is" basis.\n\n'
                    'DigiBiomics does not guarantee that wellness scores, trends, recommendations, recordings, or other information will always be complete, accurate, or suitable for every individual.\n\n'
                    'DigiBiomics does not guarantee that use of LungSense Wellness will prevent, identify, diagnose, or treat any disease or health condition.\n\n'
                    'Nothing in these Terms excludes rights or protections that cannot legally be excluded.',
              ),

              // Section 19
              _buildSection(
                number: '19',
                title: 'Limitation of Liability',
                content:
                    'To the maximum extent permitted by applicable law, DigiBiomics will not be liable for indirect, incidental, special, consequential, exemplary, or punitive damages arising from or related to your use of the Service.\n\n'
                    'This may include, where legally permitted, losses arising from reliance on wellness information, interruption of the Service, loss of data, or inability to access the Service.\n\n'
                    'Nothing in these Terms limits liability where such limitation is prohibited by applicable law.',
              ),

              // Section 20
              _buildSection(
                number: '20',
                title: 'Indemnification',
                content:
                    'To the extent permitted by applicable law, you agree to indemnify and hold harmless DigiBiomics Inc., its officers, directors, employees, contractors, and service providers from claims, liabilities, damages, losses, and expenses arising from your violation of these Terms, misuse of the Service, violation of applicable law, or infringement of third-party rights.',
              ),

              // Section 21
              _buildSection(
                number: '21',
                title: 'Regulatory Status',
                content:
                    'LungSense Wellness is intended as a wellness and self-monitoring platform and is not represented through these Terms as a medical diagnostic service.\n\n'
                    'DigiBiomics does not authorize users to rely on LungSense Wellness as a substitute for professional medical evaluation, diagnosis, or treatment.',
              ),

              // Section 22
              _buildSection(
                number: '22',
                title: 'Changes to These Terms',
                content:
                    'DigiBiomics may update these Terms from time to time to reflect changes in the Service, technology, business practices, legal requirements, or regulatory guidance.\n\n'
                    'For material changes, we will provide notice through the Service, email, or another appropriate method where required.\n\n'
                    'The updated Terms will include a revised Last Updated date. Where applicable law requires renewed consent, DigiBiomics will obtain that consent.',
              ),

              // Section 23
              _buildSection(
                number: '23',
                title: 'Governing Law',
                content:
                    'These Terms are governed by the laws applicable to DigiBiomics Inc. in Ontario, Canada, without regard to conflict-of-law principles, except where applicable mandatory laws provide otherwise.\n\n'
                    'Where you are located in a jurisdiction that provides mandatory consumer protections that cannot legally be waived, those protections remain applicable.',
              ),

              // Section 24
              _buildSection(
                number: '24',
                title: 'Contact Us',
                content:
                    'DigiBiomics Inc.\n'
                    '3052 Owls Foot Dr\n'
                    'Mississauga, ON L5M 6W5\n'
                    'Canada\n\n'
                    'General Email: info@digibiomics.com\n'
                    'Privacy Email: privacy@digibiomics.com',
              ),

              // Section 25
              _buildSection(
                number: '25',
                title: 'Acceptance',
                content:
                    'By creating an account, accessing, downloading, installing, or using LungSense Wellness, you acknowledge that:\n'
                    '• You have read and understood these Terms of Use.\n'
                    '• You agree to comply with these Terms.\n'
                    '• You understand that LungSense Wellness is a wellness and self-monitoring application.\n'
                    '• You understand that LungSense Wellness does not provide medical diagnosis, disease detection, medical screening, or treatment.\n'
                    '• You understand that wellness scores and recommendations are not a substitute for professional medical advice.\n'
                    '• You have reviewed the LungSense Wellness Privacy Policy.\n\n'
                    'Effective Date: June 16, 2026\n'
                    'Version: 1.0\n'
                    'LungSense Wellness\n'
                    'Powered by DigiBiomics Inc.',
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  '© 2026 DigiBiomics Inc. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
