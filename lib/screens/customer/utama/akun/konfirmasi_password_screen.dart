import 'package:flutter/material.dart';
import 'package:kaig/services/auth_service.dart';

class KonfirmasiPasswordScreen extends StatefulWidget {
  final Future<void> Function() onPasswordConfirmed;

  const KonfirmasiPasswordScreen({super.key, required this.onPasswordConfirmed});

  @override
  State<KonfirmasiPasswordScreen> createState() => _KonfirmasiPasswordScreenState();
}

class _KonfirmasiPasswordScreenState extends State<KonfirmasiPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true; // Added for password visibility toggle

  Future<void> _konfirmasi() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isSuccess = await _authService.verifikasiPassword(_passwordController.text);

      if (mounted) {
        if (isSuccess) {
          // If password is correct, execute the next action
          await widget.onPasswordConfirmed();
        } else {
          setState(() {
            _errorMessage = "Kata sandi salah. Silakan coba lagi.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Masukkan Kata Sandi",
          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Makes the content scrollable
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
        child: ConstrainedBox( // Ensures content takes up minimum height
          constraints: BoxConstraints(
            minHeight: screenHeight - (AppBar().preferredSize.height + MediaQuery.of(context).padding.top + (isSmallScreen ? 32.0 : 48.0)), // Account for app bar, status bar, and padding
          ),
          child: IntrinsicHeight( // Allows Column to take intrinsic height
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Masukkan kata sandi email lamamu untuk melanjutkan.",
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32), // Responsive spacing
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Kata Sandi",
                      border: const OutlineInputBorder(),
                      errorText: _errorMessage,
                      prefixIcon: const Icon(Icons.lock_outline), // Added prefix icon
                      suffixIcon: IconButton( // Toggle visibility
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Kata sandi tidak boleh kosong" : null,
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48), // Responsive spacing
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 45 : 50, // Responsive button height
                    child: ElevatedButton(
                      onPressed: _konfirmasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF304FFE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0), // Consistent border radius
                        ),
                        textStyle: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold), // Responsive font size
                      ),
                      child: const Text("LANJUTKAN"),
                    ),
                  ),
                  const Spacer(), // Pushes content to top, button to bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}