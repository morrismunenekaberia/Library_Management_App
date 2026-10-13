import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/member.dart';
import '../controllers/members_controller.dart';

/// Screen for adding a new library member or editing an existing one.
/// Supports the `createUser` switch and presents temporary passwords in a one-time dialog.
class MemberFormScreen extends StatefulWidget {
  final int? memberId;
  final Member? initialMember;

  const MemberFormScreen({
    super.key,
    this.memberId,
    this.initialMember,
  });

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _admissionNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String _status = 'active';
  bool _createUser = false;

  bool get isEditing => widget.memberId != null;

  @override
  void initState() {
    super.initState();
    final member = widget.initialMember;
    _fullNameController = TextEditingController(text: member?.fullName ?? '');
    _admissionNumberController =
        TextEditingController(text: member?.admissionNumber ?? '');
    _phoneController = TextEditingController(text: member?.phone ?? '');
    _emailController = TextEditingController(text: member?.email ?? '');
    _status = member?.status ?? 'active';
    // Clear any previous form errors when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembersController>().clearError();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _admissionNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showTemporaryPasswordDialog(
    BuildContext context,
    String username,
    String password,
  ) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.vpn_key_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Login Account Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A login account has been created for $username.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temporary Password',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            password,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Copy password',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Temporary password copied to clipboard'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This password will not be shown again. Please copy and share it with the member securely.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<MembersController>();
    final fullName = _fullNameController.text.trim();
    final admissionNumber = _admissionNumberController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (isEditing) {
      final updated = await controller.updateMember(
        widget.memberId!,
        fullName: fullName,
        admissionNumber: admissionNumber,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        status: _status,
      );

      if (mounted && updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated successfully')),
        );
        Navigator.of(context).pop(updated);
      }
    } else {
      final result = await controller.createMember(
        fullName: fullName,
        admissionNumber: admissionNumber,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        status: _status,
        createUser: _createUser,
      );

      if (mounted && result != null) {
        if (result.temporaryPassword != null &&
            result.temporaryPassword!.isNotEmpty) {
          await _showTemporaryPasswordDialog(
            context,
            admissionNumber,
            result.temporaryPassword!,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member created successfully')),
          );
        }

        if (mounted) {
          Navigator.of(context).pop(result.member);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersController = context.watch<MembersController>();
    final isSaving = membersController.isSaving;
    final formError = membersController.formErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Member' : 'Add New Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error banner
                  if (formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formError,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Jane Doe',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Admission Number
                  TextFormField(
                    controller: _admissionNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Admission Number *',
                      hintText: 'e.g. STU12345',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Admission number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'e.g. +1234567890',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      hintText: 'e.g. jane.doe@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Member Status *',
                      prefixIcon: Icon(Icons.toggle_on_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _status = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Optional Create Login Account Switch (Only shown when adding new member)
                  if (!isEditing) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: SwitchListTile(
                        value: _createUser,
                        onChanged: (val) {
                          setState(() {
                            _createUser = val;
                          });
                        },
                        title: const Text(
                          'Create login account',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Creates a student login with username matching admission number and generates a temporary password.',
                        ),
                        secondary: Icon(
                          Icons.vpn_key_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  FilledButton(
                    onPressed: isSaving ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Create Member',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
