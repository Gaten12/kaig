import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/tiket/jadwal_krl_viewer_screen.dart';

class BerandaContent extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const BerandaContent({super.key, required this.onNavigateToTab});

  Widget _buildMenuItem(BuildContext context,
      {required IconData iconData,
        required String label,
        required VoidCallback onTap,
        required bool isPrimary,
        required bool isSmallScreen}) { // Added isSmallScreen parameter
    return Container(
      height: isSmallScreen ? 120 : 140, // Responsive height
      child: Material(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0), // Responsive border radius
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF1976D2),
                ],
              )
                  : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0),
              border: Border.all(
                color: isPrimary ? Colors.transparent : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? const Color(0xFF2196F3).withOpacity(0.25)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: isSmallScreen ? 10 : 20, // Responsive blur
                  offset: Offset(0, isSmallScreen ? 4 : 8), // Responsive offset
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF2196F3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: isSmallScreen ? 28 : 32, // Responsive icon size
                    color: isPrimary ? Colors.white : const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8.0 : 16.0), // Responsive spacing
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15, // Responsive font size
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : const Color(0xFF37474F),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard({required bool isSmallScreen}) { // Added isSmallScreen
    return Container(
      // Removed fixed height to allow content to dictate height, combined with adjusted padding/font sizes
      // height: 200, // This was causing the overflow
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[600]!.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 15 : 25, // Responsive blur
                  offset: Offset(0, isSmallScreen ? 6 : 12), // Responsive offset
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Ensure it wraps its content
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12), // Responsive padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12), // Responsive border radius
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: const Color(0xFF2196F3),
                    size: isSmallScreen ? 24 : 28, // Responsive icon size
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 16), // Responsive spacing
                Text(
                  'Promo Eksklusif!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                Text(
                  'Nikmati diskon hingga 50% untuk perjalanan kereta jarak jauh. Berlaku terbatas!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Decorative elements (adjusted for responsiveness if needed, but less critical for overflow)
          Positioned(
            top: isSmallScreen ? -20 : -40,
            right: isSmallScreen ? -20 : -40,
            child: Container(
              width: isSmallScreen ? 80 : 120,
              height: isSmallScreen ? 80 : 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: isSmallScreen ? -30 : -50,
            left: isSmallScreen ? -30 : -50,
            child: Container(
              width: isSmallScreen ? 100 : 140,
              height: isSmallScreen ? 100 : 140,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, {required bool isSmallScreen}) { // Added isSmallScreen
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 24 : 32), // Responsive margin
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // Responsive padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: isSmallScreen ? 10 : 20,
            offset: Offset(0, isSmallScreen ? 4 : 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                Text(
                  'Pesan tiket kereta dengan mudah, cepat, dan terpercaya untuk perjalanan nyaman Anda',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16), // Responsive spacing
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            ),
            child: Icon(
              Icons.train_rounded,
              size: isSmallScreen ? 32 : 36, // Responsive icon size
              color: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  // _buildStatCard (not directly used in the current context, but can be made responsive)
  Widget _buildStatCard(String value, String label, IconData icon, {required bool isSmallScreen}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: isSmallScreen ? 8 : 10,
            offset: Offset(0, isSmallScreen ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: isSmallScreen ? 18 : 20),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Example breakpoint for small screens

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0), // Responsive padding
        children: <Widget>[
          _buildWelcomeCard(context, isSmallScreen: isSmallScreen), // Pass isSmallScreen
          Text(
            'Layanan Utama',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22, // Responsive font size
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16.0 : 20.0), // Responsive spacing
          Row(
            children: <Widget>[
              Expanded(
                child: _buildMenuItem(
                  context,
                  iconData: Icons.train_outlined,
                  label: 'Pesan Tiket',
                  isPrimary: true,
                  isSmallScreen: isSmallScreen, // Pass isSmallScreen
                  onTap: () {
                    onNavigateToTab(1);
                  },
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 20), // Responsive spacing
              Expanded(
                child: _buildMenuItem(
                  context,
                  iconData: Icons.train,
                  label: 'Commuter Line',
                  isPrimary: false,
                  isSmallScreen: isSmallScreen, // Pass isSmallScreen
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JadwalKrlViewerScreen())
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 24.0 : 32.0), // Responsive spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promo Terbaru',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
              // Changed Container with Material to just a flexible row for button
              Flexible( // Use Flexible to prevent overflow
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Gunakan callback untuk navigasi ke tab index 3 (PromoScreen)
                        onNavigateToTab(3);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric( // Responsive padding
                            horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 6 : 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Semua',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 12 : 14, // Responsive icon size
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16.0 : 20.0), // Responsive spacing
          _buildPromoCard(isSmallScreen: isSmallScreen), // Pass isSmallScreen
          SizedBox(height: isSmallScreen ? 16.0 : 24.0), // Responsive spacing
        ],
      ),
    );
  }
}