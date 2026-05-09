import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Terms & Conditions",
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
              "Welcome to AI Interview. By using this app, you agree to the following terms and conditions. Please read them carefully before using the application.",
              style: TextStyle(height: 1.5),
            ),

            const SizedBox(height: 20),

            _sectionTitle("1. Use of the App"),
            _sectionText(
              "You agree to use this app only for personal and educational purposes. "
                  "You must not misuse the service or attempt to disrupt its functionality.",
            ),

            _sectionTitle("2. User Accounts"),
            _sectionText(
              "You are responsible for maintaining the confidentiality of your account information "
                  "and all activities under your account.",
            ),

            _sectionTitle("3. AI-generated Content"),
            _sectionText(
              "The app provides AI-generated interview questions and feedback. "
                  "This content is for practice purposes only and may not always be 100% accurate.",
            ),

            _sectionTitle("4. Subscription & Pricing"),
            _sectionText(
              "Some features may require a paid subscription. Prices and features may change at any time.",
            ),

            _sectionTitle("5. Limitation of Liability"),
            _sectionText(
              "We are not responsible for any direct or indirect damages arising from the use of this app.",
            ),

            _sectionTitle("6. Privacy"),
            _sectionText(
              "We respect your privacy. Please refer to our Privacy Policy for more details.",
            ),

            _sectionTitle("7. Changes to Terms"),
            _sectionText(
              "We may update these Terms & Conditions at any time. Continued use of the app means acceptance of changes.",
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "© 2026 AI Interview App. All rights reserved.",
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