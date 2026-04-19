import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';
import 'notification.dart';

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
  final NotificationService _notificationService = NotificationService();

  Map<String, dynamic>? userData;
  bool isEditing = false;
  bool isSaving = false;
  String _selectedLanguage = 'English';
  bool _isHarvesting = false;
  bool _isGloballyHarvesting = false; // Track if any user is harvesting
  String? _activeHarvestingUser; // Track who is currently harvesting
  StreamSubscription<QuerySnapshot>? _globalStatusSubscription;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

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
  String? _base64Image;
  bool _useBase64 = false;

  @override
  void initState() {
    super.initState();
    userData = {};
    _initializeControllers();
    _initializeFocusNodes();
    _loadSavedLanguage();
    fetchUserData();
    _startStatusListener();
    _startGlobalStatusListener();
    _notificationService.startMachineDataMonitoring();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    setState(() {
      _selectedLanguage = savedLanguage;
    });
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
    
    _statusSubscription?.cancel();
    _globalStatusSubscription?.cancel();
    // Stop real-time machine data monitoring
    _notificationService.stopMachineDataMonitoring();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      setState(() {
        userData = doc.data() ?? {};
        _currentProfileImageUrl = userData?["profileImage"] ?? "";
        _base64Image = userData?["profileImageBase64"] ?? "";
        _useBase64 = userData?["useBase64Image"] ?? false;
        _populateControllers();
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        userData = null;
      });
    }
  }

  // Start real-time status listener
  void _startStatusListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _statusSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (mounted && snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>?;
            if (data != null) {
              final status = data['status'];
              final bool isHarvestingActive = status == 1;
              
              setState(() {
                _isHarvesting = isHarvestingActive;
                if (userData != null) {
                  userData!["status"] = status;
                }
              });
              
              print('Profile: User status updated: $status (isHarvesting: $isHarvestingActive)');
            }
          }
        }, onError: (error) {
          print('Profile: Error listening to status changes: $error');
        });
  }

  // Start global status listener to check if any user is harvesting
  void _startGlobalStatusListener() {
    _globalStatusSubscription = _firestore
        .collection('users')
        .where('status', isEqualTo: 1)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          if (mounted) {
            if (snapshot.docs.isNotEmpty) {
              // Get the first active user (there should only be one)
              final activeUser = snapshot.docs.first;
              final userData = activeUser.data() as Map<String, dynamic>?;
              final activeUserName = userData?['name'] ?? 'Unknown User';
              final currentUserId = _auth.currentUser?.uid;
              final activeUserId = activeUser.id;
              
              setState(() {
                _isGloballyHarvesting = true;
                _activeHarvestingUser = activeUserId == currentUserId ? 'You' : activeUserName;
              });
              
              print('Global: Active harvesting detected: $activeUserName ($activeUserId)');
            } else {
              setState(() {
                _isGloballyHarvesting = false;
                _activeHarvestingUser = null;
              });
              
              print('Global: No active harvesting detected');
            }
          }
        }, onError: (error) {
          print('Profile: Error listening to global status changes: $error');
        });
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
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _selectedImage = file;
          _base64Image = base64String;
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
          final ref = _storage.refFromURL(_currentProfileImageUrl!);
          await ref.delete();
        } catch (e) {
          debugPrint("Error deleting old image: $e");
          // Continue even if deletion fails
        }
      }

      // Upload new image with better error handling
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images/$fileName');
      
      final uploadTask = await ref.putFile(_selectedImage!);
      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${uploadTask.state}');
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      // Return null to trigger base64 fallback
      return null;
    }
  }

  Future<void> _saveProfile() async {
    // Validate all required fields
    final List<String> missingFields = [];
    
    if (_nameController.text.trim().isEmpty) {
      missingFields.add("Full Name");
    }
    if (_phoneController.text.trim().isEmpty) {
      missingFields.add("Phone Number");
    }
    if (_cityController.text.trim().isEmpty) {
      missingFields.add("City");
    }
    if (_barangayController.text.trim().isEmpty) {
      missingFields.add("Barangay");
    }
    if (_purokController.text.trim().isEmpty) {
      missingFields.add("Purok");
    }
    
    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all required fields: ${missingFields.join(', ')}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "city": _cityController.text.trim(),
        "barangay": _barangayController.text.trim(),
        "purok": _purokController.text.trim(),
        "pinCode": _pinCodeController.text.trim(),
        "phone": _phoneController.text.trim(),
      };

      // Handle image upload with fallback to base64
      if (_selectedImage != null) {
        if (_useBase64 && _base64Image != null) {
          // Save as base64
          updateData["profileImageBase64"] = _base64Image;
          updateData["useBase64Image"] = true;
          updateData["profileImage"] = ""; // Clear old URL
        } else {
          // Try to save to Firebase Storage, fallback to base64 on error
          try {
            final profileImageUrl = await _uploadProfileImage();
            if (profileImageUrl != null) {
              updateData["profileImage"] = profileImageUrl;
              updateData["profileImageBase64"] = ""; // Clear old base64
              updateData["useBase64Image"] = false;
            } else {
              // Fallback to base64 if storage fails
              if (_base64Image != null) {
                updateData["profileImageBase64"] = _base64Image;
                updateData["useBase64Image"] = true;
                updateData["profileImage"] = "";
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cloud storage failed, saved as base64 instead"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            // Fallback to base64 on any error
            if (_base64Image != null) {
              updateData["profileImageBase64"] = _base64Image;
              updateData["useBase64Image"] = true;
              updateData["profileImage"] = "";
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cloud storage failed, saved as base64 instead"),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        }
      }

      // Update Firestore
      await _firestore.collection("users").doc(user.uid).update(updateData);

      // Refresh user data to get the latest profile image
      await fetchUserData();

      setState(() {
        isEditing = false;
        _selectedImage = null; // Clear the temp selected image
        // Don't clear _base64Image - let fetchUserData() handle it
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
      // Don't clear _base64Image - restore it from database if needed
      _base64Image = userData?["profileImageBase64"] ?? "";
      _useBase64 = userData?["useBase64Image"] ?? false;
      _currentProfileImageUrl = userData?["profileImage"] ?? "";
      _populateControllers(); // Reset to original values
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                "Logout Account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              const Text(
                "Are you sure you want to logout?\nYou can always login back anytime.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            // ListTile(
            //   leading: const Icon(
            //     Icons.settings,
            //     color: Color(0xFF00AEEF),
            //   ),
            //   title: Text(_useBase64 ? "Use Cloud Storage" : "Use Base64"),
            //   subtitle: Text(_useBase64 ? "Save image to cloud" : "Save image as base64"),
            //   onTap: () {
            //     Navigator.pop(context);
            //     setState(() {
            //       _useBase64 = !_useBase64;
            //     });
            //   },
            // ),
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

  String _getStatusDisplay(dynamic status) {
    final statusValue = status?.toString() ?? 'active';
    
    // Check for harvest status (1 = active harvesting, 0 = inactive)
    if (statusValue == '1' || statusValue == 1) {
      return 'Active Harvesting';
    }
    if (statusValue == '0' || statusValue == 0) {
      return 'Inactive';
    }
    
    // Handle text-based status values
    switch (statusValue.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      case 'pending':
        return 'Pending';
      default:
        return statusValue[0].toUpperCase() + statusValue.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePadding = context.responsivePagePadding;
    Widget bodyContent;

    if (userData == null) {
      bodyContent = Center(
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
      );
    } else {
      bodyContent = SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 0,
          right: 0,
          top: 0,
          bottom: pagePadding.bottom + 20,
        ),
        child: ResponsiveConstrainedBox(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: pagePadding.left,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    _buildInfoSection(),
                    const SizedBox(height: 30),
                    _buildLanguageSelector(),
                    const SizedBox(height: 30),
                    if (!isEditing) ...[
                      _buildAccountInfo(),
                      const SizedBox(height: 30),
                    ],
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildContactDeveloperSection(),
                    const SizedBox(height: 20),
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        // title: const Text(
        //   'Profile',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 20,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0981D1),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0981D1), Color(0xFF0981D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // actions: [
        //   if (isEditing)
        //     IconButton(
        //       tooltip: 'Cancel',
        //       icon: const Icon(Icons.close, color: Colors.white),
        //       onPressed: isSaving ? null : _cancelEdit,
        //     ),
        // ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      )
                    : null,
              ),
              // Dynamic indicator: Check when not editing, Camera when editing
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: isEditing ? 48 : 24,
                  height: isEditing ? 48 : 24,
                  decoration: BoxDecoration(
                    color: isEditing ? const Color(0xFF0981D1) : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isEditing
                      ? IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImageSourceDialog,
                        )
                      : const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
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
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (userData!["phone"] != null &&
              userData!["phone"].toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  userData!["phone"],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
          
          // Harvest status indicator
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isHarvesting ? Colors.green.shade600 : Colors.orange.shade600,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isHarvesting ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _isHarvesting ? 'Harvesting Active' : 'Harvesting Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stackControls = constraints.maxWidth < 360;
              final titleWidget = Text(
                TranslationService.getTranslationSync('personal_information', _selectedLanguage),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              );

              if (stackControls) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    if (!isEditing)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => isEditing = true),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Edit"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0981D1),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleWidget),
                  if (!isEditing)
                    TextButton.icon(
                      onPressed: () => setState(() => isEditing = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0981D1),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          if (isEditing) ...[
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
              label: "Phone Number *",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildEditableField(
              controller: _cityController,
              focusNode: _cityFocus,
              icon: Icons.location_city,
              label: "City *",
            ),
            const SizedBox(height: 15),
            _buildEditableField(
              controller: _barangayController,
              focusNode: _barangayFocus,
              icon: Icons.location_on,
              label: "Barangay *",
            ),
            const SizedBox(height: 15),
            _buildEditableField(
              controller: _purokController,
              focusNode: _purokFocus,
              icon: Icons.home,
              label: "Purok *",
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AEEF)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 16, color: Color(0xFF00AEEF)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AEEF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            infoTile(Icons.person_outline, "Full Name", userData!["name"]),
            infoTile(Icons.phone_outlined, "Phone Number", userData!["phone"]),
            infoTile(Icons.location_city, "City", userData!["city"]),
            infoTile(Icons.location_on, "Barangay", userData!["barangay"]),
            infoTile(Icons.home, "Purok", userData!["purok"]),
          ],
        ],
      ),
    );
  }

  Widget _buildContactDeveloperSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Developer',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF0981D1).withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   // child: const Icon(
                //   //   Icons.email,
                //   //   color: Color(0xFF0981D1),
                //   //   size: 24,
                //   // ),
                // ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Developer Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Need help? Contact our developer.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // You can add email functionality here
                          print('Contact developer: devtotepai@gmail.com');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0981D1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Color(0xFF0981D1),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'devtotepai@gmail.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0981D1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // You can add phone functionality here
                          print('Contact developer: 09562590920');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0981D1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Color(0xFF0981D1),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '09562590920',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0981D1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.getTranslationSync('account_information', _selectedLanguage),
            style: const TextStyle(
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
          // infoTile(
          //   Icons.verified_user,
          //   "Status",
          //   _getStatusDisplay(userData!["status"]),
          // ),

          // Harvest status selector
          const SizedBox(height: 15),
          _buildHarvestStatusSelector(),
        ],
      ),
    );
  }

  Widget _buildHarvestStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isHarvesting ? Icons.stop_circle : Icons.play_circle,
                color: _isHarvesting ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Harvest Control",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isHarvesting 
              ? "Your harvest session is currently active. The system is ready to receive data from your device."
              : _isGloballyHarvesting
                ? "$_activeHarvestingUser is currently harvesting. Please wait for the session to end."
                : "Start a harvest session to enable data collection from your device.",
            style: TextStyle(
              fontSize: 14,
              color: _isGloballyHarvesting && !_isHarvesting 
                ? Colors.red.shade600 
                : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isGloballyHarvesting && !_isHarvesting) || (!_isProfileComplete() && !_isHarvesting) ? null : () async {
                if (_isHarvesting) {
                  await _stopHarvestSession();
                } else {
                  await _startHarvestSession();
                }
              },
              icon: Icon(
                _isHarvesting ? Icons.stop : 
                (_isGloballyHarvesting && !_isHarvesting) ? Icons.block : 
                (!_isProfileComplete()) ? Icons.warning_amber_rounded : Icons.play_arrow,
                size: 18,
              ),
              label: Text(
                _isHarvesting ? 'Stop Harvest Session' : 
                (_isGloballyHarvesting && !_isHarvesting) ? 'Harvest Session Occupied' : 
                (!_isProfileComplete()) ? 'Complete Profile Required' : 'Start Harvest Session',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHarvesting ? Colors.green : 
                               (_isGloballyHarvesting && !_isHarvesting) ? Colors.grey.shade400 : 
                               (!_isProfileComplete()) ? Colors.grey.shade400 : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: (_isGloballyHarvesting && !_isHarvesting) ? 0 : 2,
              ),
            ),
          ),
          if (_isGloballyHarvesting && !_isHarvesting) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only one harvest session can be active at a time to prevent machine conflicts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isProfileComplete() && !_isHarvesting) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please complete your personal information before starting a harvest session.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Format timestamp to month-day-year and 12-hour format
  String _formatTimestamp(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final year = timestamp.year;
    
    int hour = timestamp.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    
    return '$month-$day-$year $hour:$minute:$second $period';
  }

  // Create harvest timestamp and send notification
  Future<void> _createHarvestTimestampAndNotify(String action) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create timestamp
      final timestamp = DateTime.now();
      
      // Store timestamp in database
      await _firestore.collection('users').doc(user.uid).collection('harvest_timestamps').add({
        'timestamp': Timestamp.fromDate(timestamp),
        'created_at': Timestamp.fromDate(timestamp),
        'user_id': user.uid,
        'user_name': userData?['name'] ?? 'Unknown User',
        'action': action, // 'start_harvest' or 'stop_harvest'
        'description': '$action at ${timestamp.toString().substring(0, 19)}',
      });

      // Create notification based on action
      final notificationService = NotificationService();
      String title;
      String message;
      String type;
      
      if (action == 'start_harvest') {
        title = '🐟 Harvest Started';
        message = 'Harvesting session has started! Good luck with your harvest. (${_formatTimestamp(timestamp)})';
        type = 'harvest';
      } else {
        title = '✅ Harvest Completed';
        message = 'Harvesting session has been completed successfully! (${_formatTimestamp(timestamp)})';
        type = 'success';
      }
      
      print('Creating notification: title="$title", message="$message", type="$type"');
      
      await notificationService.addNotification(
        title: title,
        message: message,
        type: type,
      );

      print('Harvest timestamp and notification sent for action: $action');
      
      // Force UI update to show new notification
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error creating harvest timestamp: $e');
    }
  }

  // Check if all required personal information is filled up
  bool _isProfileComplete() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_cityController.text.trim().isEmpty) return false;
    if (_barangayController.text.trim().isEmpty) return false;
    if (_purokController.text.trim().isEmpty) return false;
    return true;
  }

  // Show dialog for incomplete profile
  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Complete Your Profile'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please complete your personal information before starting a harvest session.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Required fields:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...[
                'Full Name',
                'Phone Number', 
                'City',
                'Barangay',
                'Purok'
              ].map((field) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  children: [
                    Icon(
                      _isFieldComplete(field) ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 12,
                      color: _isFieldComplete(field) ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isFieldComplete(field) ? Colors.green : Colors.black87,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your profile to ensure proper harvest data tracking and management.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isEditing = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0981D1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        );
      },
    );
  }

  // Check if specific field is complete
  bool _isFieldComplete(String fieldName) {
    switch (fieldName) {
      case 'Full Name':
        return _nameController.text.trim().isNotEmpty;
      case 'Phone Number':
        return _phoneController.text.trim().isNotEmpty;
      case 'City':
        return _cityController.text.trim().isNotEmpty;
      case 'Barangay':
        return _barangayController.text.trim().isNotEmpty;
      case 'Purok':
        return _purokController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _startHarvestSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if profile is complete
      if (!_isProfileComplete()) {
        _showIncompleteProfileDialog();
        return;
      }

      // Check if another user is already harvesting
      if (_isGloballyHarvesting && !_isHarvesting) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    const Text('Harvest Session Active'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_activeHarvestingUser is currently harvesting.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Only one harvest session can be active at a time. Please wait for the current session to end or contact the active user.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, 
                               color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This restriction prevents conflicts with the single harvesting machine.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0981D1),
                    ),
                    child: const Text('Understood'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Set status to 1 (active harvesting) and store start time
      await _firestore.collection("users").doc(user.uid).update({
        "status": 1,
        "harvestStartTime": FieldValue.serverTimestamp(),
      });

      // Create timestamp and notification for harvest start
      await _createHarvestTimestampAndNotify('start_harvest');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harvest session started! Your device can now upload data."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error starting harvest session: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopHarvestSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Set status to 0 (inactive harvesting)
      await _firestore.collection("users").doc(user.uid).update({
        "status": 0,
      });

      // Create timestamp and notification for harvest stop
      await _createHarvestTimestampAndNotify('stop_harvest');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harvest session stopped."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error stopping harvest session: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: const Color(0xFF00AEEF), size: 20),
              const SizedBox(width: 8),
              const Text(
                "Update Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['active', 'inactive', 'pending'].map((status) {
              final isSelected = (userData!["status"] ?? "active") == status;
              return FilterChip(
                label: Text(status.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _updateUserStatus(status);
                  }
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFF00AEEF).withOpacity(0.2),
                checkmarkColor: const Color(0xFF00AEEF),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF00AEEF) : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserStatus(String newStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection("users").doc(user.uid).update({
        "status": newStatus,
      });

      // Refresh user data
      await fetchUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $newStatus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.getTranslationSync('language', _selectedLanguage),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                icon: const Icon(Icons.language, color: Color(0xFF0981D1)),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Tagalog', child: Text('Tagalog')),
                  DropdownMenuItem(value: 'Kamayo', child: Text('Kamayo')),
                ],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                    await LanguagePersistence.saveLanguage(newValue);
                  }
                },
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade500,
              Colors.red.shade600,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  TranslationService.getTranslationSync('logout', _selectedLanguage),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
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
    final bool isNarrow = MediaQuery.sizeOf(context).width < 420;
    final bool hasValue = value != null && value.toString().isNotEmpty;
    final String displayValue = hasValue ? value.toString() : "Not set";
    final TextStyle valueStyle = TextStyle(
      fontSize: 15,
      color: hasValue ? Colors.black87 : Colors.grey,
      fontWeight: FontWeight.w500,
    );

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
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF0981D1)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayValue,
                  style: valueStyle,
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: const Color(0xFF0981D1)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    displayValue,
                    style: valueStyle,
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
              ],
            ),
    );
  }

  ImageProvider? _getProfileImage() {
    // Priority: Selected image > Base64 > Network URL > Default
    if (_selectedImage != null) {
      return FileImage(_selectedImage!) as ImageProvider;
    }
    
    // Check base64 image (regardless of _useBase64 flag for display purposes)
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_base64Image!));
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
        // Fall back to other options
      }
    }
    
    if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
      return NetworkImage(_currentProfileImageUrl!);
    }
    
    // Use a simple colored circle as fallback instead of missing asset
    return null; // Will show default background color
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
