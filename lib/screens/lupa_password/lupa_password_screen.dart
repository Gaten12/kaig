import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail; // Bisa diisi dari layar password jika ada

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email reset kata sandi telah dikirim ke ${_emailController.text.trim()}. Silakan periksa inbox Anda.')),
          );
          Navigator.of(context).pop(); // Kembali ke layar sebelumnya
        }
      } on FirebaseAuthException catch (e) {
        String message = "Gagal mengirim email reset.";
        if (e.code == 'user-not-found') {
          message = "Email tidak terdaftar.";
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Example breakpoint for small screens

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Masukkan Email",
          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20), // Responsive font size
        ),
        backgroundColor: const Color(0xFFC50000), // Latar belakang merah gelap
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Tombol kembali putih
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView( // Prevents bottom overflow when keyboard appears
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
        child: ConstrainedBox( // Ensures content can take up enough height on larger screens
          constraints: BoxConstraints(
            minHeight: screenHeight - (AppBar().preferredSize.height + MediaQuery.of(context).padding.top + (isSmallScreen ? 16.0 : 24.0)),
          ),
          child: IntrinsicHeight( // Allows Column to take minimum necessary height for its children
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Konten rata kiri
                children: <Widget>[
                  Text(
                    "Masukkan alamat email Anda untuk menerima link reset kata sandi.",
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16), // Responsive font size
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20), // Responsive spacing
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Masukkan Email Anda",
                      border: const OutlineInputBorder(), // Menambahkan border
                      prefixIcon: const Icon(Icons.email_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                      if (!value.contains('@') || !value.contains('.')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 30), // Responsive spacing
                  const Spacer(), // Pushes the button to the bottom if content is short
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 45 : 50, // Responsive button height
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF304FFE), // Latar belakang biru
                        foregroundColor: Colors.white, // Teks putih
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(fontSize: isSmallScreen ? 15 : 16), // Responsive font size
                      ),
                      onPressed: _sendResetEmail,
                      child: const Text(
                        "LANJUTKAN",
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16), // Bottom padding for scroll view
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}