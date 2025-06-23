import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../services/admin_firestore_service.dart';
import 'form_user_screen.dart';

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({super.key});

  @override
  State<ListUserScreen> createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  String _searchQuery = "";
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();

  static const Color _charcoalGray = Color(0xFF374151);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _electricBlue = Color(0xFF3B82F6);
  static const Color _lightGray = Color(0xFFF9FAFB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _redError = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterUsers();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        final emailLower = user.email.toLowerCase();
        final noTeleponLower = user.noTelepon.toLowerCase();
        final roleLower = user.role.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();
        return emailLower.contains(searchQueryLower) ||
            noTeleponLower.contains(searchQueryLower) ||
            roleLower.contains(searchQueryLower);
      }).toList();
    }
  }

  // Fungsi placeholder untuk Cloud Function
  Future<void> _resetPassword(UserModel user) async {
    // TODO: Implementasi pemanggilan Cloud Function untuk reset password
    // Contoh:
    // try {
    //   final callable = FirebaseFunctions.instance.httpsCallable('resetUserPassword');
    //   await callable.call({'userId': user.id});
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Email reset password terkirim ke ${user.email}')),
    //     );
    //   }
    // } catch (e) {
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Gagal mengirim email reset password: $e')),
    //     );
    //   }
    // }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fitur Reset Password untuk ${user.email} akan datang melalui Cloud Function!')),
      );
    }
    print("Reset Password for: ${user.email}");
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    // TODO: Implementasi pemanggilan Cloud Function untuk mengaktifkan/menonaktifkan user
    // Contoh:
    // try {
    //   final callable = FirebaseFunctions.instance.httpsCallable('toggleUserAccountStatus');
    //   await callable.call({'userId': user.id, 'disable': !user.isDisabled}); // Anda perlu menambahkan properti isDisabled ke UserModel jika ingin melacak status ini di Firestore
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Status akun ${user.email} berhasil diubah!')),
    //     );
    //   }
    // } catch (e) {
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Gagal mengubah status akun: $e')),
    //     );
    //   }
    // }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fitur Toggle Status Akun untuk ${user.email} akan datang melalui Cloud Function!')),
      );
    }
    print("Toggle Status for: ${user.email}");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: _charcoalGray,
        title: const Text(
          "Daftar User",
          style: TextStyle(
            color: _pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: _pureWhite),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_electricBlue, Colors.blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _pureWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _electricBlue.withAlpha((255 * 0.1).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Pencarian User",
                      hintText: "Cari berdasarkan email, nomor telepon, atau role...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search_rounded, color: _electricBlue),
                      filled: true,
                      fillColor: _pureWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _electricBlue, width: 2),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _adminService.getUserList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error Stream User: ${snapshot.error}");
                  return _buildErrorState("Error: ${snapshot.error}");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allUsers = [];
                  _filterUsers();
                  return _buildEmptyState("Belum ada data user.");
                }

                if (_allUsers != snapshot.data!) {
                  _allUsers = snapshot.data!;
                  _filterUsers();
                }

                if (_filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildEmptyState("User tidak ditemukan.");
                }
                if (_filteredUsers.isEmpty && _allUsers.isEmpty) {
                  return _buildEmptyState("Belum ada data user.");
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // If you want to add a FAB for adding users, you can uncomment and implement
      // floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor.withAlpha((255 * 0.5).round())),
        boxShadow: [
          BoxShadow(
            color: _charcoalGray.withAlpha((255 * 0.06).round()),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _electricBlue.withAlpha((255 * 0.05).round()),
                  _electricBlue.withAlpha((255 * 0.02).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_electricBlue, _electricBlue.withAlpha((255 * 0.8).round())],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: _textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInfoChip(Icons.phone_rounded, user.noTelepon, _electricBlue),
                      const SizedBox(height: 6),
                      _buildInfoChip(Icons.assignment_ind_rounded, user.role.toUpperCase(), _charcoalGray),
                    ],
                  ),
                ),
                // Menambahkan PopupMenuButton di sini
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormUserScreen(userToEdit: user),
                        ),
                      );
                    } else if (value == 'reset_password') {
                      _resetPassword(user);
                    } else if (value == 'toggle_status') {
                      _toggleUserStatus(user);
                    } else if (value == 'delete') {
                      _showDeleteDialog(user);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: _electricBlue),
                          SizedBox(width: 8),
                          Text('Edit User Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Reset Password'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on_rounded, color: Colors.green), // Atau Icons.toggle_off jika sudah nonaktif
                          SizedBox(width: 8),
                          Text('Toggle Account Status'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: _redError),
                          SizedBox(width: 8),
                          Text('Delete User'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: _textSecondary),
                ),
              ],
            ),
          ),
          // Bagian ini sekarang opsional atau bisa dihapus karena aksi sudah ada di menu
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       // Action buttons (dapat dipindahkan ke PopupMenuButton)
          //       _buildActionButton(
          //         icon: Icons.edit_rounded,
          //         label: "Edit",
          //         color: _electricBlue,
          //         onPressed: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => FormUserScreen(userToEdit: user),
          //             ),
          //           );
          //         },
          //       ),
          //       const SizedBox(width: 12),
          //       _buildActionButton(
          //         icon: Icons.delete_rounded,
          //         label: "Hapus",
          //         color: _redError,
          //         onPressed: () => _showDeleteDialog(user),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.2).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: _charcoalGray.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _electricBlue.withAlpha((255 * 0.1).round()),
                        _electricBlue.withAlpha((255 * 0.05).round())
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_electricBlue),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Memuat Data User",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mohon tunggu sebentar...",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: _charcoalGray.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _electricBlue.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: 56,
                    color: _electricBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Data user akan muncul di sini ketika tersedia",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border:
              Border.all(color: _redError.withAlpha((255 * 0.2).round())),
              boxShadow: [
                BoxShadow(
                  color: _redError.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _redError.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: _redError,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Terjadi Kesalahan",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: _redError,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _redError.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: _redError,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Penghapusan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Anda yakin ingin menghapus user berikut?',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lightGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      user.email,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: _redError,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _borderColor),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _redError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${user.email} berhasil dihapus',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: _electricBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus user: $e',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: _redError,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }
}