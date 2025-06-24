import 'package:flutter/material.dart';
import 'package:kaig/models/user_model.dart';
import 'package:kaig/screens/admin/screens/form_user_screen.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';
import 'package:kaig/screens/admin/services/admin_auth_service.dart';

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({super.key});

  @override
  _ListUserScreenState createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final AdminAuthService _adminAuthService = AdminAuthService();
  final Color _electricBlue = const Color(0xFF00BFFF);
  final Color _redError = const Color(0xFFFF5252);

  Future<void> _resetPassword(UserModel user) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Anda yakin ingin mengirim email reset password ke ${user.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kirim')),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    try {
      await _adminAuthService.resetPassword(user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email reset password berhasil dikirim ke ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal reset password: $e'), backgroundColor: _redError),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final bool? disable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Status Akun"),
        content: Text("Pilih aksi untuk akun ${user.email}"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Aktifkan Akun", style: TextStyle(color: Colors.green))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text("Nonaktifkan Akun", style: TextStyle(color: _redError))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Batal")),
        ],
      ),
    );

    if (disable == null) return;

    try {
      await _adminAuthService.toggleAccountStatus(user.id, disable);
      final status = disable ? "dinonaktifkan" : "diaktifkan";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun ${user.email} berhasil ${status}.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: _redError),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Anda yakin ingin menghapus user ${user.email}?\nAksi ini tidak dapat dibatalkan.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: _redError)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminAuthService.deleteUser(user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${user.email} berhasil dihapus'),
              backgroundColor: _electricBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus user: $e'),
              backgroundColor: _redError,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _navigateToForm({UserModel? user}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => FormUserScreen(user: user),
      ),
    )
        .then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengguna'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<List<UserModel>>(
        // --- PERBAIKAN DI SINI ---
        stream: _adminService.getUserList(), // Menggunakan metode yang benar
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pengguna.'));
          }
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${user.role}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(user: user);
                      } else if (value == 'reset') {
                        _resetPassword(user);
                      } else if (value == 'status') {
                        _toggleUserStatus(user);
                      } else if (value == 'delete') {
                        _showDeleteDialog(user);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.lock_reset),
                          title: Text('Reset Password'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'status',
                        child: ListTile(
                          leading: Icon(Icons.toggle_on),
                          title: Text('Ubah Status'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}