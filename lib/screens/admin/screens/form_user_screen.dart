import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../../../models/user_model.dart';
import '../services/admin_firestore_service.dart';

class FormUserScreen extends StatefulWidget {
  final UserModel userToEdit; // userToEdit is now mandatory as we only allow editing

  const FormUserScreen({super.key, required this.userToEdit});

  @override
  State<FormUserScreen> createState() => _FormUserScreenState();
}

class _FormUserScreenState extends State<FormUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _emailController;
  late TextEditingController _noTeleponController;
  late String _selectedRole;

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  final List<String> _roles = ['costumer', 'admin']; // Changed 'customer' to 'costumer' here

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userToEdit.email);
    _noTeleponController = TextEditingController(text: widget.userToEdit.noTelepon);
    _selectedRole = widget.userToEdit.role;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _noTeleponController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedUser = UserModel(
        id: widget.userToEdit.id,
        email: _emailController.text,
        noTelepon: _noTeleponController.text,
        role: _selectedRole,
        createdAt: widget.userToEdit.createdAt, // Preserve original creation timestamp
      );

      try {
        await _adminService.updateUser(updatedUser);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'User berhasil diperbarui!',
                style: TextStyle(color: pureWhite),
              ),
              backgroundColor: electricBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyimpan user: $e',
                style: const TextStyle(color: pureWhite),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final BorderSide defaultBorderSide = BorderSide(
      color: charcoalGray.withAlpha((255 * 0.3).round()),
      width: 1.5,
    );
    final BorderSide focusedBorderSide = BorderSide(
      color: electricBlue,
      width: 2.0,
    );
    const BorderSide errorBorderSide = BorderSide(
      color: Colors.red,
      width: 1.5,
    );

    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: defaultBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: focusedBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder focusedErrorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide.copyWith(width: 2.0),
      borderRadius: BorderRadius.circular(12.0),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        elevation: 0,
        title: const Text(
          "Edit User",
          style: TextStyle(
            color: pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: pureWhite, size: 28),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8.0,
              shadowColor: charcoalGray.withAlpha((255 * 0.2).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              color: pureWhite,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: electricBlue.withAlpha((255 * 0.1).round()),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 32,
                                color: electricBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Edit Data User',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: charcoalGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Perbarui informasi detail user',
                              style: TextStyle(
                                fontSize: 14,
                                color: charcoalGray.withAlpha((255 * 0.7).round()),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                          color: charcoalGray,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email User',
                          labelStyle: TextStyle(
                            color: charcoalGray.withAlpha((255 * 0.7).round()),
                            fontSize: 16,
                          ),
                          hintText: 'Contoh: user@example.com',
                          hintStyle: TextStyle(
                            color: charcoalGray.withAlpha((255 * 0.4).round()),
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.email,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!GetUtils.isEmail(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      TextFormField(
                        controller: _noTeleponController,
                        style: TextStyle(
                          color: charcoalGray,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon',
                          labelStyle: TextStyle(
                            color: charcoalGray.withAlpha((255 * 0.7).round()),
                            fontSize: 16,
                          ),
                          hintText: 'Contoh: 081234567890',
                          hintStyle: TextStyle(
                            color: charcoalGray.withAlpha((255 * 0.4).round()),
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.phone,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor telepon tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: TextStyle(
                            color: charcoalGray.withAlpha((255 * 0.7).round()),
                            fontSize: 16,
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.assignment_ind,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: _roles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role.capitalizeFirst!,
                              style: TextStyle(color: charcoalGray, fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Role tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32.0),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [electricBlue, electricBlue.withAlpha((255 * 0.8).round())],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: electricBlue.withAlpha((255 * 0.3).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save,
                                color: pureWhite,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: pureWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}