import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/profile_avatar.dart';
import 'avatar_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
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
    final tokens = HorizonThemeTokens.of(context);
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textHigh),
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HORIZON // PROTOCOL',
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.ionCyan,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Edit Personal Details',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: HorizonDimensions.marginMobile,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Hero
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tokens.ionCyan.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: ProfileAvatar(
                                name: user?.name ?? '',
                                bytes: _photoChanged
                                    ? _photo
                                    : context.watch<AuthProvider>().avatarBytes,
                                size: 84,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isUpdating || _picking ? null : _choosePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: tokens.ionCyan,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tokens.ionCyan.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  size: 16,
                                  color: Color(0xFF00363C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          HorizonButton(
                            text: 'Choose Photo',
                            icon: Icons.photo_library_outlined,
                            variant: HorizonButtonVariant.secondary,
                            expandWidth: false,
                            height: 38,
                            isLoading: _picking,
                            onPressed: _isUpdating || _picking ? null : _choosePhoto,
                          ),
                          if ((_photoChanged
                                  ? _photo
                                  : context.watch<AuthProvider>().avatarBytes) !=
                              null)
                            HorizonButton(
                              text: 'Remove',
                              icon: Icons.delete_outline,
                              variant: HorizonButtonVariant.ghost,
                              expandWidth: false,
                              height: 38,
                              onPressed: _isUpdating
                                  ? null
                                  : () {
                                      setState(() {
                                        _photo = null;
                                        _photoChanged = true;
                                      });
                                      _checkForChanges();
                                    },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HorizonTextField(
                        controller: _nameController,
                        label: "Full Name",
                        hintText: "Enter your full name",
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

                      HorizonTextField(
                        controller: _emailController,
                        label: "Email Address",
                        prefixIcon: Icons.mail_outline_rounded,
                        enabled: false,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "You can update your name. Email changes require verification and are currently managed by system administrators.",
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.textMedium,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Action
                HorizonButton(
                  text: 'Save Changes',
                  icon: Icons.check_circle_outline,
                  variant: HorizonButtonVariant.primary,
                  isLoading: _isUpdating,
                  onPressed: _hasChanges ? _handleSave : null,
                ),
                const SizedBox(height: 12),

                // Cancel Button
                HorizonButton(
                  text: 'Cancel',
                  variant: HorizonButtonVariant.ghost,
                  onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
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
