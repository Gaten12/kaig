import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/tiket/jadwal_krl_viewer_screen.dart';


class BerandaContent extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const BerandaContent({super.key, required this.onNavigateToTab});

  Widget _buildMenuItem(BuildContext context,
      {required IconData iconData,
        required String label,
        required VoidCallback onTap,
        required bool isPrimary}) {
    return Container(
      height: 140,
      child: Material(
        borderRadius: BorderRadius.circular(24.0),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
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
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: isPrimary ? Colors.transparent : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? const Color(0xFF2196F3).withAlpha((255 * 0.25).round())
                      : Colors.grey.withAlpha((255 * 0.15).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withAlpha((255 * 0.2).round())
                        : const Color(0xFF2196F3).withAlpha((255 * 0.1).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 32,
                    color: isPrimary ? Colors.white : const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
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

  Widget _buildPromoCard() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[600]!.withAlpha((255 * 0.3).round()),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // Decorative elements
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((255 * 0.05).round()),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withAlpha((255 * 0.1).round()),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Color(0xFF2196F3),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Promo Eksklusif!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nikmati diskon hingga 50% untuk perjalanan kereta jarak jauh. Berlaku terbatas!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha((255 * 0.85).round()),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesan tiket kereta dengan mudah, cepat, dan terpercaya untuk perjalanan nyaman Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.train_rounded,
              size: 36,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          _buildWelcomeCard(context),
          Text(
            'Layanan Utama',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildMenuItem(
                  context,
                  iconData: Icons.train_outlined,
                  label: 'Pesan Tiket',
                  isPrimary: true,
                  onTap: () {
                    onNavigateToTab(1);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildMenuItem(
                  context,
                  iconData: Icons.train,
                  label: 'Commuter Line',
                  isPrimary: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const JadwalKrlViewerScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promo Terbaru',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          _buildPromoCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}