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
       appBar: AppBar(title: Text("Lupa Kata Sandi")),
       body: Padding(
         padding: EdgeInsets.all(16.0),
         child: Form(
           key: _formKey,
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: <Widget>[
               Text("Masukkan alamat email Anda untuk menerima link reset kata sandi."),
               SizedBox(height: 20),
               TextFormField(
                 controller: _emailController,
                 decoration: InputDecoration(labelText: "Email"),
                 keyboardType: TextInputType.emailAddress,
                 validator: (value) {
                   if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                   if (!value.contains('@')) return 'Format email tidak valid';
                   return null;
                 },
               ),
               SizedBox(height: 20),
               _isLoading
                   ? CircularProgressIndicator()
                   : ElevatedButton(
                       onPressed: _sendResetEmail,
                       child: Text("Kirim Email Reset"),
                     ),
             ],
           ),
         ),
       ),
     );
   }
 }