import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Last updated: May 2026",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            const Text(
              "AI Interview respects your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use our app.",
              style: TextStyle(height: 1.5),
            ),

            const SizedBox(height: 20),

            _sectionTitle("1. Information We Collect"),
            _sectionText(
              "We may collect basic user information such as name, email, and usage data to improve your experience.",
            ),

            _sectionTitle("2. How We Use Your Data"),
            _sectionText(
              "We use your data to provide AI interview features, improve performance, and personalize your experience.",
            ),

            _sectionTitle("3. AI Processing"),
            _sectionText(
              "Your interview answers may be processed by AI models to generate feedback. We do not use this data for advertising.",
            ),

            _sectionTitle("4. Data Storage"),
            _sectionText(
              "Your data is securely stored and protected. We take reasonable steps to prevent unauthorized access.",
            ),

            _sectionTitle("5. Third-Party Services"),
            _sectionText(
              "We may use third-party services (like AI APIs or analytics tools) that follow their own privacy policies.",
            ),

            _sectionTitle("6. Data Sharing"),
            _sectionText(
              "We do not sell, trade, or rent your personal data to anyone.",
            ),

            _sectionTitle("7. Your Rights"),
            _sectionText(
              "You can request access, update, or deletion of your data by contacting support.",
            ),

            _sectionTitle("8. Changes to This Policy"),
            _sectionText(
              "We may update this Privacy Policy from time to time. Changes will be reflected in the app.",
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "If you have any questions, contact: support@yourapp.com",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }
}