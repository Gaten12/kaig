 import 'package:flutter/material.dart';
 import 'package:firebase_auth/firebase_auth.dart';

 class ForgotPasswordScreen extends StatefulWidget {
   final String? initialEmail; // Bisa diisi dari layar password jika ada
   ForgotPasswordScreen({this.initialEmail});

   @override
   _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
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

   Future<void> _sendResetEmail() async {
     if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       try {
         await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Email reset kata sandi telah dikirim ke ${_emailController.text.trim()}. Silakan periksa inbox Anda.')),
         );
         Navigator.of(context).pop(); // Kembali ke layar sebelumnya
       } on FirebaseAuthException catch (e) {
         String message = "Gagal mengirim email reset.";
         if (e.code == 'user-not-found') {
           message = "Email tidak terdaftar.";
         }
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(message), backgroundColor: Colors.red),
         );
       } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}"), backgroundColor: Colors.red),
         );
       } finally {
         if (mounted) {
           setState(() => _isLoading = false);
         }
       }
     }
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Masukkan Email",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC50000), // Latar belakang merah gelap
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Tombol kembali putih
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Konten rata kiri
            children: <Widget>[
              // Teks ini tidak diubah sesuai permintaan
              const Text(
                "Masukkan alamat email Anda untuk menerima link reset kata sandi.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Masukkan Email Anda",
                  border: OutlineInputBorder(), // Menambahkan border
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  if (!value.contains('@') || !value.contains('.')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Tombol lebar
                  backgroundColor: const Color(0xFF304FFE), // Latar belakang biru
                  foregroundColor: Colors.white, // Teks putih
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _sendResetEmail,
                child: const Text(
                  "LANJUTKAN",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
   }
 }