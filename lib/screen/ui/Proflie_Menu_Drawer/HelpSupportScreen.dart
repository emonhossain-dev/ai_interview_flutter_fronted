import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // ===== EMAIL SUPPORT =====
  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: Uri.encodeFull(
        'subject=Help & Support&body=Hello, I need help with...',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // ===== WHATSAPP SUPPORT =====
  Future<void> _openWhatsApp() async {
    final phone = "8801XXXXXXXXX";
    final message = "Hello, I need help with AI Interview app";

    final url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== HEADER =====
            const Text(
              "How can we help you?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Find answers to common questions or contact support.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // ===== CONTACT OPTIONS =====
            Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: _openEmail,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.blue),
                          SizedBox(height: 8),
                          Text("Email"),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: _openWhatsApp,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.chat, color: Colors.green),
                          SizedBox(height: 8),
                          Text("WhatsApp"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ===== FAQ TITLE =====
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ===== FAQ LIST =====
            _faqItem(
              "What is AI Interview?",
              "AI Interview helps you practice real interview questions using AI feedback.",
            ),

            _faqItem(
              "Is this app free?",
              "Yes, basic features are free. Premium plans may unlock advanced features.",
            ),

            _faqItem(
              "Can I see my interview history?",
              "Yes, all your interviews are saved in the history section.",
            ),

            _faqItem(
              "How does AI feedback work?",
              "Our AI analyzes your answers and gives improvement suggestions.",
            ),

            _faqItem(
              "How can I delete my data?",
              "You can contact support or go to settings to request data deletion.",
            ),

            const SizedBox(height: 30),

            // ===== FOOTER =====
            Center(
              child: Text(
                "Still need help? Contact support anytime.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== FAQ WIDGET =====
  Widget _faqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}