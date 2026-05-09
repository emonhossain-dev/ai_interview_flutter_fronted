import 'package:ai_interview/screen/ui/Proflie_Menu_Drawer/HelpSupportScreen.dart';
import 'package:ai_interview/screen/ui/Proflie_Menu_Drawer/PrivacyPolicyScreen.dart';
import 'package:ai_interview/screen/ui/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../Service/auth_service.dart';
import '../../models/NetworkResponse.dart';
import '../../models/Resume.dart';
import '../../models/ResumeResponse.dart';
import '../../models/UserModel.dart';
import '../../network/Api_URL.dart';
import '../../network/network_called.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../../utils/DeviceIdService.dart';
import '../../utils/ImagePickerHelper.dart';
import 'Proflie_Menu_Drawer/Pricing_Screen.dart';
import 'Proflie_Menu_Drawer/TermsAndConditionsScreen.dart';
import 'Proflie_Menu_Drawer/about_app.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  File? _selectedImage;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  UserModel? userModel;
  final user = AuthService.currentUser;


  // ── Edit Mode State ──────────────────────────────────────
  bool _isEditMode = false;
  bool _isSaving = false;

  // ── Personal Info ────────────────────────────────────────
  final _nameController = TextEditingController(text: 'N/A');
  final _phoneController = TextEditingController(text: 'N/A');
  final _locationController = TextEditingController(text: 'App Developer');

  // ── Target Job Role ───────────────────────────────────────
  final List<String> _allRoles = ['Senior Product Manager', 'UX Designer', 'Growth Lead'];
  final List<String> _selectedRoles = ['Senior Product Manager'];

  // ── Experience Level ──────────────────────────────────────
  String _selectedExperience = 'Mid-Senior Level';
  final List<Map<String, String>> _experienceLevels = [
    {'title': 'Entry Level', 'sub': '0-2 years experience'},
    {'title': 'Mid-Senior Level', 'sub': '3-8 years experience'},
    {'title': 'Director / Executive', 'sub': '8+ years experience'},
  ];

  // ── Resume ────────────────────────────────────────────────
  final List<ResumeFile> _resumes = [];
  final List<ResumeModel> resumesRes = [];
  bool _isUploadingResume = false;
  double _uploadProgress = 0.0;

  // ── Colors ────────────────────────────────────────────────
  final Color _green = const Color(0xFF2ECC8F);





  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ─────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────


  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final response = await NetworkCaller.putRequest(
        ApiURL.Profile_Update_URL,
        {
          "name": _nameController.text,
          "mobile": _phoneController.text,
        },
      );

      setState(() => _isSaving = false);

      if (response.isSuccess) {
        setState(() => _isEditMode = false);
        _showSnack('✅ Profile updated successfully!', isError: false);
      } else {
        _showSnack('❌ ${response.errorMessage}', isError: true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _isEditMode = false;
      });

      _showSnack('❌ Something went wrong', isError: true);
    }
  }

  Future<void> _pickAndUploadResume() async {
    if (_resumes.length >= 1) {
      _showSnack('Maximum 1 resume allowed.', isError: true);
      return;
    }

    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.path == null) return;

    if (file.size > 5 * 1024 * 1024) {
      _showSnack('Max 5MB allowed', isError: true);
      return;
    }

    setState(() {
      _isUploadingResume = true;
      _uploadProgress = 0;
    });

    try {
      // ✅ IMPORTANT: backend field name must match (file)
      final response = await NetworkCaller.uploadResume(
        url: ApiURL.uploadResume,
        userId: 1,
        title: file.name,
        summary: "Uploaded from mobile app", // ✅ MUST ADD THIS
        file: File(file.path!),
        onSendProgress: (sent, total) {
          if (total != -1) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );


      setState(() => _isUploadingResume = false);

      if (response.isSuccess) {
        setState(() {
          _resumes.clear(); // ✅ since only 1 resume allowed
          _resumes.add(
            ResumeFile(
              name: file.name,
              size: _formatSize(file.size),
              updatedAt: "Just now",
              localPath: file.path,
            ),
          );
          _uploadProgress = 0;
        });

        _showSnack("Resume uploaded successfully", isError: false);
      } else {
        _showSnack(response.errorMessage ?? "Upload failed", isError: true);
      }
    } catch (e) {
      setState(() => _isUploadingResume = false);
      _showSnack("Upload failed: $e", isError: true);
    }
  }

  void _deleteResume(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 28),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              const Text(
                'Delete Resume?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ──
              Text(
                '"${_resumes[index].name}"',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              const Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _DeleteApiCall(ctx, index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      // ── Drawer ──────────────────────────────────────────────
      drawer: buildDrawer(context),


      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 16),
                    _buildTargetJobRoleCard(),
                    const SizedBox(height: 16),
                    _buildExperienceLevelCard(),
                    const SizedBox(height: 16),
                    _buildResumeManagementCard(),
                    const SizedBox(height: 16),
                    _buildProPlanCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ===== TITLE =====
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ===== APP =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "ACCOUNT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Pricing & Plans'),
                onTap: () {

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PricingPage(),
                    ),
                  );


                },
              ),


              const Divider(height: 28),

              // ===== LEGAL =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "LEGAL",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );


                },
              ),

              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms & Conditions'),
                onTap: () {

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsScreen(),
                    ),
                  );


                },
              ),

              const Divider(height: 28),

              // ===== SUPPORT =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "SUPPORT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );

                },
              ),

              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Rate App'),
                onTap: () async {

                  Navigator.pop(context);

                  final InAppReview inAppReview = InAppReview.instance;

                  final url = Uri.parse(
                      "https://play.google.com/store/apps/details?id=com.iqiyi.i18n"
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }

                  /*if (await inAppReview.isAvailable()) {
                    await inAppReview.requestReview();
                  } else {
                    // fallback → Play Store open
                    await inAppReview.openStoreListing(
                      appStoreId: "YOUR_APP_ID",
                    );
                  }*/
                },
              ),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About App'),
                onTap: () {

                  // drawer close
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutAppScreen(),
                    ),
                  );
                },
              ),



              const SizedBox(height: 30),

              const Divider(),

              // ===== LOGOUT =====
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  _LogOutApiCalled();
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xFFF2F4F7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Menu Icon ──────────────────────────────────────
          // ── Menu Icon ──────────────────────────────────────
          Builder(  // ← এটা add করো
            builder: (scaffoldContext) => GestureDetector(
              onTap: () {
                if (_isEditMode) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Discard Changes?'),
                      content: const Text('Your unsaved changes will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Stay'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _isEditMode = false);
                            Scaffold.of(scaffoldContext).openDrawer(); // ← scaffoldContext
                          },
                          child: const Text('Discard', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                } else {
                  Scaffold.of(scaffoldContext).openDrawer(); // ← scaffoldContext
                }
              },
              child: const Icon(Icons.menu, size: 26, color: Colors.black87),
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Profile Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              if (_isEditMode) {
                _saveProfile();
              } else {
                setState(() => _isEditMode = true);
              }
            },
            icon: Icon(
              _isEditMode ? Icons.check_circle_outline : Icons.edit_outlined,
              size: 26,
              color: _isEditMode ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            // এটা রাখো:
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!) as ImageProvider
                  : (userModel?.profilePic != null &&
                  userModel!.profilePic!.isNotEmpty &&
                  userModel!.profilePic != "null")
                  ? NetworkImage(ApiURL.baseURL + userModel!.profilePic!)
                  : null,
              child: (_selectedImage == null &&
                  (userModel?.profilePic == null ||
                      userModel!.profilePic!.isEmpty ||
                      userModel!.profilePic == "null"))
                  ? const Icon(Icons.person, color: Colors.white, size: 40)
                  : null,
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: GestureDetector(
                onTap: _isEditMode ? () {_showPickerOptions();} : null,
                child: AnimatedOpacity(
                  opacity: _isEditMode ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          userModel?.name ?? "N/A",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          userModel?.email ?? "N/A",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        if (_isEditMode) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Text(
              '✏️  Editing Mode',
              style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isEditMode
            ? Border.all(color: _green.withOpacity(0.25), width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel,
                style: TextStyle(
                    fontSize: 14, color: _green, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: _isEditMode,
          style: TextStyle(
            fontSize: 14,
            color: _isEditMode ? Colors.black87 : Colors.black54,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: _isEditMode ? Colors.white : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _green.withOpacity(0.5)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _green, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 12),
          _buildTextField('Phone Number', _phoneController),
          const SizedBox(height: 12),
          _buildTextField('Current Position', _locationController),
        ],
      ),
    );
  }

  Widget _buildTargetJobRoleCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Target Job Role',
              actionLabel: _isEditMode ? 'Edit' : null, onAction: () {}),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allRoles.map((role) {
              final isSelected = _selectedRoles.contains(role);
              return GestureDetector(
                onTap: _isEditMode
                    ? () => setState(() {
                  if (isSelected) {
                    _selectedRoles.remove(role);
                  } else {
                    _selectedRoles.add(role);
                  }
                })
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _green.withOpacity(0.12) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _green : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? _green : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceLevelCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Experience Level'),
          const SizedBox(height: 12),
          ..._experienceLevels.map((level) {
            final isSelected = _selectedExperience == level['title'];
            return GestureDetector(
              onTap: _isEditMode
                  ? () => setState(() => _selectedExperience = level['title']!)
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? _green.withOpacity(0.06) : Colors.white,
                  border: Border.all(
                    color: isSelected ? _green : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? _green : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            level['sub']!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: level['title']!,
                      groupValue: _selectedExperience,
                      onChanged: _isEditMode
                          ? (val) => setState(() => _selectedExperience = val!)
                          : null,
                      activeColor: _green,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResumeManagementCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resume Management',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_resumes.length}/1 slots used',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Upload Area ──────────────────────────────────
          GestureDetector(
            onTap: _isUploadingResume ? null : _pickAndUploadResume,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: _isUploadingResume ? _green.withOpacity(0.04) : Colors.transparent,
                border: Border.all(
                  color: _isUploadingResume ? _green : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isUploadingResume
                  ? Column(
                children: [
                  Icon(Icons.upload_rounded, color: _green, size: 24),
                  const SizedBox(height: 8),
                  const Text(
                    'Uploading...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_green),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: _green),
                  ),
                ],
              )
                  : Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.upload_rounded, color: _green, size: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload resume',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PDF, DOCX up to 5MB',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Uploaded Resumes List ────────────────────────
          ..._resumes.asMap().entries.map((entry) {
            final i = entry.key;
            final resume = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${resume.updatedAt} • ${resume.size}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteResume(i),
                    child: Icon(Icons.delete_outline,
                        color: Colors.grey.shade500, size: 22),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _loadUserData() {
    final user = AuthService.currentUser;

    print("👤 currentUser: $user");          // null হলে সেখানেই সমস্যা
    print("📄 resume: ${user?.resume}");
    print("📄 resume id: ${user?.resume?.id}");

    if (user == null) return;

    userModel = user;
    _nameController.text = user.name;
    _phoneController.text = user.mobile;

    _resumes.clear();
    if (user.resume != null && user.resume!.title != null) {
      _resumes.add(
        ResumeFile(
          name: user.resume!.title ?? 'Resume',
          size: '',
          updatedAt: user.resume!.createdAt ?? '',
          localPath: null,
        ),
      );
    }

    print("📋 resumes count: ${_resumes.length}"); // 0 হলে resume null বা id null
  }

  Widget _buildProPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('👑 ', style: TextStyle(fontSize: 18)),
                  Text('Pro Plan',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlimited AI matches, priority support, and advanced analytics.',
            style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Renews on',
                      style: TextStyle(fontSize: 11, color: Colors.white38)),
                  SizedBox(height: 2),
                  Text('Nov 15, 2024',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Manage Plan',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    File? file;

    if (source == ImageSource.gallery) {
      file = await ImagePickerHelper.pickFromGallery();
    } else {
      file = await ImagePickerHelper.pickFromCamera();
    }

    if (file != null) {
      setState(() {
        _image = file;
        _selectedImage = file;
      });


      _uploadProfileImage(file);

    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _DeleteApiCall(ctx, index) async {

    if (userModel == null) return;

    final userId = userModel!.id;

    final response = await NetworkCaller.deleteResume(
      url: "${ApiURL.ResumeDelete}$userId",
    );

    if (response.isSuccess && response.statusCode==200) {

      final message = response.responseData["message"];
      print(message);

      Navigator.pop(ctx);
      setState(() => _resumes.removeAt(index));
      _showSnack(message, isError: true);

    } else {
      print(response.errorMessage);
    }
  }
  
  
  Future<void> _LogOutApiCalled() async {

    final deviceId = await DeviceIdService.getDeviceId();
    final refresh_token = await AuthService.getRefreshToken();


    final response = await NetworkCaller.postJson(ApiURL.LogOut_URL,
        {
          "device_id": deviceId,
          "refresh_token": refresh_token
        });


    if (response.isSuccess && response.statusCode == 200) {

      final message = response.responseData["message"];
      //
      AuthService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SignInScreen(),
        ),
      );

      _showSnack(message, isError: false);


    } else {
      debugPrint("❌ ${response.errorMessage}");
    }



  }


  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      final response = await NetworkCaller.uploadProfileImage(
        url: ApiURL.Profile_Pic_Update_URL,
        file: imageFile,
      );

      if (response.isSuccess) {
        final message = response.responseData["message"];
        _showSnack(message, isError: false);
      } else {
        debugPrint(response.errorMessage);
        _showSnack( "Upload failed", isError: true);
      }
    } catch (e) {
      _showSnack("Upload failed", isError: true);
      debugPrint("Upload error: $e");
    }
  }



}