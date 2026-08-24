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
                            Icons.privacy_tip_rounded,
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
                                'Privacy Policy',
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
                        'LungSense Wellness does not provide medical diagnosis, disease detection, medical screening, or treatment. It is not intended to replace professional medical advice, diagnosis, or treatment.',
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
                title: 'Introduction',
                content:
                    'DigiBiomics Inc. ("DigiBiomics", "we", "us", or "our") respects your privacy and is committed to protecting the personal information you provide when using LungSense Wellness.\n\n'
                    'LungSense Wellness is a respiratory wellness and self-monitoring application designed to help users track respiratory wellness and symptoms, record cough and breathing sounds, monitor personal wellness trends, complete wellness check-ins, receive general wellness recommendations, and maintain a history of respiratory wellness information.\n\n'
                    'LungSense Wellness does not provide medical diagnosis, disease detection, medical screening, or treatment. It is not intended to replace professional medical advice, diagnosis, or treatment.\n\n'
                    'This Privacy Policy explains what information we collect, how we use it, how it is protected, when it may be shared, and the rights available to you.\n\n'
                    'This Privacy Policy applies to the LungSense Wellness mobile application, web application, APIs, and related services operated by DigiBiomics Inc.',
              ),

              // Section 2
              _buildSection(
                number: '2',
                title: 'Who We Are',
                content:
                    'DigiBiomics Inc. is a Canadian health-technology company incorporated in Ontario, Canada. DigiBiomics operates the LungSense Wellness platform and is responsible for the personal information collected through the Service.\n\n'
                    'Contact Information:\n'
                    'DigiBiomics Inc.\n'
                    '3052 Owls Foot Dr\n'
                    'Mississauga, ON L5M 6W5\n'
                    'Canada\n'
                    'General Email: info@digibiomics.com',
              ),

              // Section 3
              _buildSection(
                number: '3',
                title: 'Information We Collect',
                content:
                    '3.1 Account Information\n'
                    '• Name\n'
                    '• Email address\n'
                    '• Account credentials\n'
                    '• User profile information\n'
                    '• Age or age range\n'
                    '• Other information provided during registration or profile setup\n\n'
                    '3.2 Wellness and Respiratory Information\n'
                    'Depending on the features you use, LungSense Wellness may collect information that you voluntarily provide during wellness check-ins or when using respiratory features, including:\n'
                    '• Respiratory symptoms\n'
                    '• Cough-related information\n'
                    '• Breathing-related information\n'
                    '• Respiratory audio recordings\n'
                    '• Lifestyle and wellness information\n'
                    '• Physical activity information\n'
                    '• Sleep information\n'
                    '• Water intake information\n'
                    '• Smoking information\n'
                    '• Vaccination-related information\n'
                    '• Other wellness information provided by you\n\n'
                    '3.3 Wellness Scores and Trends\n'
                    'LungSense Wellness may generate wellness scores, wellness trends, historical comparisons, personalized wellness information, and general wellness recommendations. These outputs are intended to help you understand and monitor your wellness over time. They are not medical diagnoses, medical screening results, or treatment recommendations.\n\n'
                    '3.4 Device and Technical Information\n'
                    '• Device type\n'
                    '• Operating system\n'
                    '• Application version\n'
                    '• IP address\n'
                    '• Approximate location, such as country or province/state\n'
                    '• Application usage information\n'
                    '• Session information\n'
                    '• Crash reports\n'
                    '• Error reports\n'
                    '• Push notification tokens\n\n'
                    '3.5 Information Collected Automatically\n'
                    'When you use LungSense Wellness, certain technical information may be collected automatically to maintain application functionality, understand application usage, improve performance, identify errors and crashes, improve the user experience, and maintain application security. We do not use this information for targeted advertising.',
              ),

              // Section 4
              _buildSection(
                number: '4',
                title: 'How We Use Your Information',
                content:
                    '4.1 Providing LungSense Wellness\n'
                    '• Create and maintain your account.\n'
                    '• Provide wellness check-ins.\n'
                    '• Store your wellness history.\n'
                    '• Process respiratory recordings.\n'
                    '• Calculate wellness scores.\n'
                    '• Display personal trends.\n'
                    '• Provide general wellness recommendations.\n'
                    '• Provide requested application features.\n'
                    '• Send service-related notifications.\n\n'
                    '4.2 Improving the Application\n'
                    '• Improve application functionality.\n'
                    '• Understand how users interact with the Service.\n'
                    '• Identify and fix technical problems.\n'
                    '• Improve usability and performance.\n'
                    '• Develop new wellness features.\n'
                    '• Validate application functionality.\n\n'
                    '4.3 Research and Scientific Purposes\n'
                    'Where permitted by applicable law, de-identified or aggregated information may be used for scientific research, wellness research, validation studies, academic publications, statistical analysis, and product development. Identifiable personal information will not be used in research publications without appropriate legal authorization and consent where required.',
              ),

              // Section 5
              _buildSection(
                number: '5',
                title: 'Consent',
                content:
                    'Where LungSense Wellness collects sensitive health or wellness information, we may request your explicit consent before collecting or processing that information.\n\n'
                    'During onboarding or when activating specific features, we may explain what information will be collected, why it is collected, how it will be used, whether information may be shared, how long information may be retained, and how you can withdraw consent or request deletion.\n\n'
                    'You may withdraw consent where processing is based on consent. Withdrawal of consent does not affect processing that occurred lawfully before withdrawal.',
              ),

              // Section 6
              _buildSection(
                number: '6',
                title: 'Microphone and Other Device Permissions',
                content:
                    '• Microphone: The microphone may be used to record cough or breathing sounds for respiratory wellness tracking.\n\n'
                    '• Notifications: Notifications may be used for wellness reminders, check-in reminders, and service notifications.\n\n'
                    '• Storage: Where applicable, storage may be used to temporarily store recordings before secure processing or upload.\n\n'
                    '• Camera: If a camera feature is introduced, its purpose will be clearly explained before permission is requested.\n\n'
                    'Users may deny optional permissions. Doing so may limit specific features while allowing continued use of other parts of the application.',
              ),

              // Section 7
              _buildSection(
                number: '7',
                title: 'Data Sharing',
                content:
                    '7.1 Service Providers\n'
                    'We may use third-party providers for cloud hosting, data storage, application infrastructure, security monitoring, analytics, email delivery, notification delivery, and technical support. Such providers may process information only for purposes necessary to provide their services to DigiBiomics.\n\n'
                    '7.2 Research Partners\n'
                    'De-identified or aggregated information may be shared with universities, research institutions, academic partners, and healthcare or wellness organizations. Such sharing will be subject to applicable agreements and legal or ethical requirements.\n\n'
                    '7.3 Legal Requirements\n'
                    'We may disclose information where required by applicable law, court orders, government authorities, regulatory requirements, or valid legal processes.\n\n'
                    '7.4 Business Transfers\n'
                    'If DigiBiomics is involved in a merger, acquisition, restructuring, financing, or sale of assets, personal information may be transferred as part of that transaction, subject to applicable privacy requirements. Where required, users will be notified of material changes affecting how their information is used.\n\n'
                    '7.5 What We Do Not Do\n'
                    '• Does not sell personal information.\n'
                    '• Does not use identifiable health information for targeted advertising.\n'
                    '• Does not share identifiable health information with employers or insurers without appropriate consent.\n'
                    '• Does not sell personal information to data brokers.',
              ),

              // Section 8
              _buildSection(
                number: '8',
                title: 'Data Retention',
                content:
                    'We retain personal information only for as long as reasonably necessary for the purposes for which it was collected or as required by applicable law.\n\n'
                    '• Account data: During the active account plus 2 years after account closure.\n'
                    '• Identifiable health and biometric data: During active use plus 1 year, unless earlier deletion is requested.\n'
                    '• Generated wellness outputs: 2 years from generation, or longer where required by applicable law.\n'
                    '• De-identified and aggregated information: May be retained for research and development purposes.\n'
                    '• Audit and security records: 3 years.\n'
                    '• Legal and regulatory records: As required by applicable law.\n\n'
                    'When applicable retention periods expire, identifiable information will be securely deleted or anonymized.',
              ),

              // Section 9
              _buildSection(
                number: '9',
                title: 'Your Privacy Rights',
                content:
                    '• Access: Request information about the personal information we hold about you.\n'
                    '• Correction: Request correction of inaccurate or incomplete information.\n'
                    '• Deletion: Request deletion of your personal information, subject to legal retention requirements.\n'
                    '• Withdraw Consent: Withdraw consent where processing is based on consent.\n'
                    '• Data Portability: Request your information in a structured, commonly used, machine-readable format where required and technically feasible.\n'
                    '• Restriction or Objection: Request restriction of or object to certain processing activities where applicable.',
              ),

              // Section 10
              _buildSection(
                number: '10',
                title: 'How to Exercise Your Rights',
                content:
                    'To exercise your privacy rights, contact:\n\n'
                    'Email: privacy@digibiomics.com\n'
                    'Subject: Privacy Rights Request - [Your Name]\n\n'
                    'We will respond to privacy requests within the timeframe required by applicable law.',
              ),

              // Section 11
              _buildSection(
                number: '11',
                title: 'Children and Minors',
                content:
                    'LungSense Wellness is not directed at children under 13. We do not knowingly collect personal information from children under 13 without appropriate parental or guardian consent.\n\n'
                    'For users between 13 and 17, appropriate parental or authorized representative consent may be required depending on the circumstances and applicable law.\n\n'
                    'If we become aware that personal information from a child under 13 has been collected without appropriate consent, we will take reasonable steps to delete it.',
              ),

              // Section 12
              _buildSection(
                number: '12',
                title: 'Data Security',
                content:
                    'DigiBiomics implements reasonable technical and organizational safeguards designed to protect personal information against unauthorized access, disclosure, alteration, or destruction.\n\n'
                    '• Encryption of data in transit.\n'
                    '• Encryption of data at rest.\n'
                    '• Authentication controls.\n'
                    '• Role-based access controls.\n'
                    '• Access logging.\n'
                    '• Security monitoring.\n'
                    '• Intrusion detection.\n'
                    '• Vulnerability testing.\n'
                    '• Staff privacy and security training.\n\n'
                    'No method of electronic transmission or storage can guarantee absolute security. If a security incident occurs, DigiBiomics will follow applicable breach notification requirements.',
              ),

              // Section 13
              _buildSection(
                number: '13',
                title: 'International Data Transfers',
                content:
                    'DigiBiomics is based in Canada. Depending on the infrastructure and service providers used by LungSense Wellness, information may be processed or stored in Canada or other countries. Where required by applicable law, appropriate safeguards will be implemented for international transfers.\n\n'
                    'For users in the European Union or United Kingdom, applicable transfer mechanisms such as Standard Contractual Clauses may be used where required.',
              ),

              // Section 14
              _buildSection(
                number: '14',
                title: 'Cookies and Tracking Technologies',
                content:
                    'The LungSense web application may use cookies and similar technologies.\n\n'
                    '• Essential cookies: Required for authentication, sessions, and core functionality.\n'
                    '• Analytics technologies: Used to understand application usage and improve performance.\n\n'
                    'LungSense Wellness does not use advertising cookies or tracking technologies for targeted advertising. Users may manage cookie preferences through their browser settings.',
              ),

              // Section 15
              _buildSection(
                number: '15',
                title: 'Third-Party Links and Services',
                content:
                    'LungSense Wellness may contain links to third-party websites or services. Those third parties may have their own privacy policies and terms. DigiBiomics is not responsible for the privacy practices of third-party services that it does not control.',
              ),

              // Section 16
              _buildSection(
                number: '16',
                title: 'No Medical Diagnosis',
                content:
                    'LungSense Wellness is a wellness and self-monitoring platform.\n\n'
                    '• Does not diagnose diseases.\n'
                    '• Does not detect diseases.\n'
                    '• Does not provide medical screening.\n'
                    '• Does not prescribe treatment.\n'
                    '• Does not recommend medications.\n'
                    '• Does not replace a healthcare professional.\n'
                    '• Does not provide emergency medical services.\n\n'
                    'Wellness scores, trends, symptom information, recordings, and recommendations provided through the application are intended for general wellness and self-monitoring purposes. If you have health concerns or symptoms that require medical attention, consult a qualified healthcare professional.',
              ),

              // Section 17
              _buildSection(
                number: '17',
                title: 'Changes to This Privacy Policy',
                content:
                    'We may update this Privacy Policy from time to time to reflect changes to the Service, technology, our data practices, applicable laws, or regulatory guidance.\n\n'
                    'When material changes are made, we will update the Last Updated date and provide notice where required. Where a change requires fresh consent under applicable law, we will obtain that consent.',
              ),

              // Section 18
              _buildSection(
                number: '18',
                title: 'Canadian Privacy Law',
                content:
                    'DigiBiomics is committed to complying with applicable Canadian privacy requirements, including PIPEDA and applicable provincial privacy legislation.\n\n'
                    '• Accountability.\n'
                    '• Identifying purposes.\n'
                    '• Consent.\n'
                    '• Limiting collection.\n'
                    '• Limiting use, disclosure, and retention.\n'
                    '• Accuracy.\n'
                    '• Safeguards.\n'
                    '• Openness.\n'
                    '• Individual access.\n'
                    '• Ability to challenge compliance.',
              ),

              // Section 19
              _buildSection(
                number: '19',
                title: 'European Users',
                content:
                    'Where applicable, users in the European Economic Area and United Kingdom may have additional rights under GDPR and UK GDPR, including rights of access, correction, deletion, restriction, objection, data portability, withdrawal of consent, and the right to lodge a complaint with a supervisory authority.\n\n'
                    'Where required, appropriate safeguards will be implemented for international data transfers.',
              ),

              // Section 20
              _buildSection(
                number: '20',
                title: 'App Store Privacy',
                content:
                    'LungSense Wellness may be distributed through the Google Play Store and Apple App Store. DigiBiomics will provide privacy disclosures required by applicable platform policies. The information collected and permissions requested may vary depending on the features available in the application.',
              ),

              // Section 21
              _buildSection(
                number: '21',
                title: 'Contact Us',
                content:
                    'Privacy Officer\n'
                    'DigiBiomics Inc.\n'
                    '3052 Owls Foot Dr\n'
                    'Mississauga, ON L5M 6W5\n'
                    'Canada\n\n'
                    'Privacy Email: privacy@digibiomics.com\n'
                    'General Email: info@digibiomics.com',
              ),

              // Section 22
              _buildSection(
                number: '22',
                title: 'Complaints',
                content:
                    'If you are not satisfied with our response to a privacy concern, you may have the right to lodge a complaint with the relevant privacy regulator in your jurisdiction. Your rights and available complaint mechanisms depend on your jurisdiction.\n\n'
                    '• Canada: Office of the Privacy Commissioner of Canada.\n'
                    '• European Union/EEA: Relevant national data protection authority.\n'
                    '• United Kingdom: Information Commissioner\'s Office.\n'
                    '• India: Relevant authority under applicable Indian data-protection law.\n\n'
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
