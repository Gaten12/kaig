import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../services/admin_firestore_service.dart';

class FormUserScreen extends StatefulWidget {
  final UserModel? user; // Nullable, null berarti mode 'Tambah Baru'
  const FormUserScreen({super.key, this.user});

  @override
  State<FormUserScreen> createState() => _FormUserScreenState();
}

class _FormUserScreenState extends State<FormUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _emailController;
  late TextEditingController _noTeleponController;
  late String _selectedRole;
  late bool _isEditMode;

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  // Sesuaikan dengan data yang ada, 'costumer' atau 'customer'
  final List<String> _roles = ['costumer', 'admin'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.user != null;

    // Inisialisasi controller berdasarkan mode
    _emailController = TextEditingController(text: _isEditMode ? widget.user!.email : '');
    _noTeleponController = TextEditingController(text: _isEditMode ? widget.user!.noTelepon : '');
    _selectedRole = _isEditMode ? widget.user!.role : _roles.first;
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

      // CATATAN PENTING:
      // Mode 'Tambah' saat ini hanya membuat dokumen di Firestore.
      // Ini TIDAK membuat user bisa login. Untuk fungsionalitas penuh,
      // Anda harus menggunakan Firebase Function untuk membuat user
      // di Firebase Authentication terlebih dahulu, lalu simpan datanya ke Firestore.

      final userModel = UserModel(
        id: _isEditMode ? widget.user!.id : '', // ID kosong untuk user baru
        email: _emailController.text,
        noTelepon: _noTeleponController.text,
        role: _selectedRole,
        createdAt: _isEditMode ? widget.user!.createdAt : Timestamp.now(),
      );

      try {
        if (_isEditMode) {
          await _adminService.updateUser(userModel);
        } else {
          await _adminService.addUser(userModel);
        }

        if (context.mounted) {
          final message = _isEditMode ? 'User berhasil diperbarui!' : 'User berhasil ditambahkan!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(color: pureWhite),
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
    // Styling for text fields (same as your original code)
    final BorderSide defaultBorderSide = BorderSide(color: charcoalGray.withAlpha(65), width: 1.5);
    final BorderSide focusedBorderSide = BorderSide(color: electricBlue, width: 2.0);
    const BorderSide errorBorderSide = BorderSide(color: Colors.red, width: 1.5);
    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(borderSide: defaultBorderSide, borderRadius: BorderRadius.circular(12.0));
    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(borderSide: focusedBorderSide, borderRadius: BorderRadius.circular(12.0));
    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(borderSide: errorBorderSide, borderRadius: BorderRadius.circular(12.0));
    final OutlineInputBorder focusedErrorOutlineInputBorder = OutlineInputBorder(borderSide: errorBorderSide.copyWith(width: 2.0), borderRadius: BorderRadius.circular(12.0));

    // Dynamic text based on mode
    final String appBarTitle = _isEditMode ? "Edit User" : "Tambah User Baru";
    final String cardTitle = _isEditMode ? "Edit Data User" : "Data User Baru";
    final String cardSubtitle = _isEditMode ? "Perbarui informasi detail user" : "Isi detail untuk user baru";
    final String buttonText = _isEditMode ? "Simpan Perubahan" : "Tambah User";
    final IconData buttonIcon = _isEditMode ? Icons.save : Icons.add;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(color: pureWhite, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: pureWhite, size: 28),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 8.0,
          shadowColor: charcoalGray.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          color: pureWhite,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Card Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: electricBlue.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_isEditMode ? Icons.edit_note : Icons.person_add_alt_1, size: 32, color: electricBlue),
                      ),
                      const SizedBox(height: 16),
                      Text(cardTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: charcoalGray)),
                      const SizedBox(height: 8),
                      Text(cardSubtitle, style: TextStyle(fontSize: 14, color: charcoalGray.withOpacity(0.7)), textAlign: TextAlign.center),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Email Text Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email User',
                      labelStyle: TextStyle(color: charcoalGray.withOpacity(0.7)),
                      hintText: 'user@example.com',
                      enabledBorder: defaultOutlineInputBorder,
                      focusedBorder: focusedOutlineInputBorder,
                      errorBorder: errorOutlineInputBorder,
                      focusedErrorBorder: focusedErrorOutlineInputBorder,
                      prefixIcon: const Icon(Icons.email, color: electricBlue),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !GetUtils.isEmail(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Phone Number Text Field
                  TextFormField(
                    controller: _noTeleponController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      labelStyle: TextStyle(color: charcoalGray.withOpacity(0.7)),
                      hintText: '081234567890',
                      enabledBorder: defaultOutlineInputBorder,
                      focusedBorder: focusedOutlineInputBorder,
                      errorBorder: errorOutlineInputBorder,
                      focusedErrorBorder: focusedErrorOutlineInputBorder,
                      prefixIcon: const Icon(Icons.phone, color: electricBlue),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                      labelStyle: TextStyle(color: charcoalGray.withOpacity(0.7)),
                      enabledBorder: defaultOutlineInputBorder,
                      focusedBorder: focusedOutlineInputBorder,
                      prefixIcon: const Icon(Icons.assignment_ind, color: electricBlue),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role.capitalizeFirst!, style: const TextStyle(color: charcoalGray)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) => setState(() => _selectedRole = newValue!),
                    validator: (value) => value == null ? 'Role tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 32.0),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(buttonIcon, color: pureWhite, size: 20),
                      label: Text(
                        buttonText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: pureWhite),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: electricBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        elevation: 4,
                        shadowColor: electricBlue.withOpacity(0.4),
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
