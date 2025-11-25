import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _barangayController;
  late TextEditingController _purokController;
  late TextEditingController _pinCodeController;
  late TextEditingController _phoneController;

  // Focus nodes
  late FocusNode _nameFocus;
  late FocusNode _cityFocus;
  late FocusNode _barangayFocus;
  late FocusNode _purokFocus;
  late FocusNode _pinCodeFocus;
  late FocusNode _phoneFocus;

  // Profile image
  File? _selectedImage;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFocusNodes();
    fetchUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _barangayController = TextEditingController();
    _purokController = TextEditingController();
    _pinCodeController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _initializeFocusNodes() {
    _nameFocus = FocusNode();
    _cityFocus = FocusNode();
    _barangayFocus = FocusNode();
    _purokFocus = FocusNode();
    _pinCodeFocus = FocusNode();
    _phoneFocus = FocusNode();

    // Listen to focus changes for UI updates
    _nameFocus.addListener(() => setState(() {}));
    _cityFocus.addListener(() => setState(() {}));
    _barangayFocus.addListener(() => setState(() {}));
    _purokFocus.addListener(() => setState(() {}));
    _pinCodeFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _barangayController.dispose();
    _purokController.dispose();
    _pinCodeController.dispose();
    _phoneController.dispose();

    _nameFocus.dispose();
    _cityFocus.dispose();
    _barangayFocus.dispose();
    _purokFocus.dispose();
    _pinCodeFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      setState(() {
        userData = doc.data();
        _currentProfileImageUrl = userData?["profileImage"] ?? "";
        _populateControllers();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (userData != null) {
      _nameController.text = userData!["name"] ?? "";
      _cityController.text = userData!["city"] ?? "";
      _barangayController.text = userData!["barangay"] ?? "";
      _purokController.text = userData!["purok"] ?? "";
      _pinCodeController.text = userData!["pinCode"] ?? "";
      _phoneController.text = userData!["phone"] ?? "";
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: ${e.toString()}")),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Delete old image if exists
      if (_currentProfileImageUrl != null &&
          _currentProfileImageUrl!.isNotEmpty) {
        try {
          final oldRef = _storage.refFromURL(_currentProfileImageUrl!);
          await oldRef.delete();
        } catch (e) {
          debugPrint("Error deleting old image: $e");
        }
      }

      // Upload new image
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      throw e;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name is required")));
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Upload image if selected
      String? profileImageUrl = _currentProfileImageUrl;
      if (_selectedImage != null) {
        profileImageUrl = await _uploadProfileImage();
      }

      // Update Firestore
      await _firestore.collection("users").doc(user.uid).update({
        "name": _nameController.text.trim(),
        "city": _cityController.text.trim(),
        "barangay": _barangayController.text.trim(),
        "purok": _purokController.text.trim(),
        "pinCode": _pinCodeController.text.trim(),
        "phone": _phoneController.text.trim(),
        if (profileImageUrl != null) "profileImage": profileImageUrl,
      });

      // Refresh user data
      await fetchUserData();

      setState(() {
        isEditing = false;
        _selectedImage = null;
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _selectedImage = null;
      _populateControllers(); // Reset to original values
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00AEEF)),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF00AEEF),
              ),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required FocusNode focusNode,
    required TextEditingController controller,
    IconData? icon,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool isFilled = controller.text.isNotEmpty;

    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: isFocused || isFilled
                  ? const Color(0xFF00AEEF)
                  : Colors.grey,
            )
          : null,
      labelText: labelText,
      labelStyle: TextStyle(
        color: isFocused ? const Color(0xFF00AEEF) : Colors.grey,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF00AEEF),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isFocused ? Colors.blue.shade50 : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0981D1),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: isSaving ? null : _cancelEdit,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No user data found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchUserData,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0981D1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : (_currentProfileImageUrl != null &&
                                            _currentProfileImageUrl!.isNotEmpty
                                        ? NetworkImage(_currentProfileImageUrl!)
                                        : const AssetImage(
                                            'assets/default_avatar.png',
                                          )),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0981D1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: _showImageSourceDialog,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userData!["name"] ?? "No Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userData!["email"] ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (userData!["phone"] != null &&
                            userData!["phone"].toString().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                userData!["phone"],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Form or Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (!isEditing)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    isEditing = true;
                                  });
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Edit"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0981D1),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        if (isEditing) ...[
                          // Edit Mode - Form Fields
                          _buildEditableField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            icon: Icons.person_outline,
                            label: "Full Name *",
                          ),
                          const SizedBox(height: 15),
                          _buildEditableField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            icon: Icons.phone_outlined,
                            label: "Phone Number",
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),
                          _buildEditableField(
                            controller: _cityController,
                            focusNode: _cityFocus,
                            icon: Icons.location_city,
                            label: "City",
                          ),
                          const SizedBox(height: 15),
                          _buildEditableField(
                            controller: _barangayController,
                            focusNode: _barangayFocus,
                            icon: Icons.location_on,
                            label: "Barangay",
                          ),
                          const SizedBox(height: 15),
                          _buildEditableField(
                            controller: _purokController,
                            focusNode: _purokFocus,
                            icon: Icons.home,
                            label: "Purok",
                          ),

                          const SizedBox(height: 25),

                          // Save/Cancel Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : _cancelEdit,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF00AEEF),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF00AEEF),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00AEEF),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Save Changes",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // View Mode - Info Tiles
                          infoTile(
                            Icons.person_outline,
                            "Full Name",
                            userData!["name"],
                          ),
                          infoTile(
                            Icons.phone_outlined,
                            "Phone Number",
                            userData!["phone"],
                          ),
                          infoTile(
                            Icons.location_city,
                            "City",
                            userData!["city"],
                          ),
                          infoTile(
                            Icons.location_on,
                            "Barangay",
                            userData!["barangay"],
                          ),
                          infoTile(Icons.home, "Purok", userData!["purok"]),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Additional Context Section
                  if (!isEditing) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Account Information",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          infoTile(
                            Icons.email_outlined,
                            "Email",
                            userData!["email"],
                            isEmail: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // Logout Button at the bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: Image.asset(
                          'assets/icon/logout.png',
                          height: 20,
                          width: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        labelText: label,
        focusNode: focusNode,
        controller: controller,
        icon: icon,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget infoTile(
    IconData icon,
    String label,
    String? value, {
    bool isEmail = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0981D1)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              (value != null && value.toString().isNotEmpty)
                  ? value.toString()
                  : "Not set",
              style: TextStyle(
                fontSize: 15,
                color: (value != null && value.toString().isNotEmpty)
                    ? Colors.black87
                    : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Not available";
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return "${date.day}/${date.month}/${date.year}";
      }
      return timestamp.toString();
    } catch (e) {
      return "Not available";
    }
  }
}
