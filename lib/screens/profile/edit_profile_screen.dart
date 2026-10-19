import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/profile_avatar.dart';
import 'avatar_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.picker});
  final ImagePicker? picker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  late String _initialName;
  late String _initialEmail;

  Uint8List? _photo;
  bool _photoChanged = false;
  bool _picking = false;
  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  Future<void> _previewPhoto(XFile file) async {
    if (await file.length() > 8 * 1024 * 1024) {
      throw Exception('Choose a photo under 8 MB.');
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => AvatarEditor(bytes: bytes)),
    );
    if (cropped == null || !mounted) return;
    setState(() {
      _photo = cropped;
      _photoChanged = true;
    });
    _checkForChanges();
  }

  Future<void> _recoverPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final recovered = await _picker.retrieveLostData();
      if (!mounted ||
          recovered.isEmpty ||
          recovered.files?.isNotEmpty != true) {
        return;
      }
      await _previewPhoto(recovered.files!.first);
    } catch (_) {
      /* A cancelled/missing previous selection does not block editing. */
    }
  }

  Future<void> _choosePhoto() async {
    if (_picking || _isUpdating) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      await _previewPhoto(file);
    } catch (_) {
      if (mounted) {
        CustomToast.showError(
          context,
          'Unable to open photo. Try a JPEG or PNG, or check gallery access in Android Settings.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _initialName = user?.name ?? '';
    _initialEmail = user?.email ?? '';

    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);

    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recoverPhoto();
    });
  }

  void _checkForChanges() {
    final changed =
        _nameController.text.trim() != _initialName ||
        _emailController.text.trim() != _initialEmail ||
        _photoChanged;
    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_hasChanges || _isUpdating) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<AuthProvider>();
    var success = await provider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && _photoChanged) success = await provider.saveAvatar(_photo);
    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      CustomToast.showSuccess(context, "Profile details updated successfully");
      Navigator.of(context).pop();
    } else {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to update profile",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ProfileAvatar(
                    name: user?.name ?? '',
                    bytes: _photoChanged
                        ? _photo
                        : context.watch<AuthProvider>().avatarBytes,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isUpdating || _picking
                            ? null
                            : _choosePhoto,
                        icon: _picking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose photo'),
                      ),
                      if ((_photoChanged
                              ? _photo
                              : context.watch<AuthProvider>().avatarBytes) !=
                          null)
                        TextButton(
                          onPressed: _isUpdating
                              ? null
                              : () {
                                  setState(() {
                                    _photo = null;
                                    _photoChanged = true;
                                  });
                                  _checkForChanges();
                                },
                          child: const Text('Remove photo'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Form Fields
                AppTextField(
                  controller: _nameController,
                  label: "Full Name",
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: "Email Address",
                  readOnly: true,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Email is required";
                    }
                    if (!RegExp(
                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(val.trim())) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Subtle helper text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "You can update your name. Email changes require a verification service and are currently unavailable.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save action - only active when changes exist
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hasChanges ? 1.0 : 0.45,
                  child: AppButton(
                    text: "SAVE CHANGES",
                    isLoading: _isUpdating,
                    onPressed: _hasChanges ? _handleSave : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text("CANCEL"),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
