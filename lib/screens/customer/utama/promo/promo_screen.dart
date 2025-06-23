import 'package:flutter/material.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final List<Map<String, dynamic>> _promoList = [
    {
      'title': 'Diskon 50% Kereta Eksekutif',
      'description': 'Nikmati perjalanan mewah dengan harga terjangkau',
      'discount': '50%',
      'validUntil': '31 Desember 2024',
      'colors': [Color(0xFF2196F3), Color(0xFF1976D2)],
      'icon': Icons.star_rounded,
      'isActive': true,
    },
    {
      'title': 'Promo Weekend Special',
      'description': 'Potongan harga untuk perjalanan akhir pekan',
      'discount': '25%',
      'validUntil': '15 Januari 2025',
      'colors': [Color(0xFF4CAF50), Color(0xFF388E3C)],
      'icon': Icons.weekend_rounded,
      'isActive': true,
    },
    {
      'title': 'Cashback Pembayaran Digital',
      'description': 'Dapatkan cashback hingga Rp 50.000',
      'discount': 'Cashback',
      'validUntil': '28 Februari 2025',
      'colors': [Color(0xFFFF9800), Color(0xFFF57C00)],
      'icon': Icons.account_balance_wallet_rounded,
      'isActive': true,
    },
    {
      'title': 'Promo Rombongan',
      'description': 'Diskon khusus untuk pembelian tiket berkelompok',
      'discount': '15%',
      'validUntil': '31 Maret 2025',
      'colors': [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      'icon': Icons.groups_rounded,
      'isActive': true,
    },
    {
      'title': 'Early Bird Discount',
      'description': 'Pesan lebih awal, hemat lebih banyak',
      'discount': '30%',
      'validUntil': '10 Januari 2025',
      'colors': [Colors.grey[600]!, Colors.grey[700]!],
      'icon': Icons.schedule_rounded,
      'isActive': false,
    },
  ];

  Widget _buildPromoCard(Map<String, dynamic> promo, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20), // Responsive margin
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: promo['colors'],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0), // Responsive border radius
              boxShadow: [
                BoxShadow(
                  color: (promo['colors'][0] as Color).withOpacity(0.3),
                  blurRadius: isSmallScreen ? 15 : 20, // Responsive blur
                  offset: Offset(0, isSmallScreen ? 6 : 8), // Responsive offset
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 24.0),
                onTap: promo['isActive']
                    ? () {
                  _showPromoDetail(context, promo, isSmallScreen); // Pass context and isSmallScreen
                }
                    : null,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 18 : 24), // Responsive padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12), // Responsive padding
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
                            ),
                            child: Icon(
                              promo['icon'],
                              color: Colors.white,
                              size: isSmallScreen ? 24 : 28, // Responsive icon size
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 5 : 6), // Responsive padding
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // Responsive border radius
                            ),
                            child: Text(
                              promo['discount'],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16, // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: promo['colors'][0],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
                      Text(
                        promo['title'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                      Text(
                        promo['description'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Berlaku hingga: ${promo['validUntil']}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12, // Responsive font size
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (!promo['isActive'])
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 3 : 4), // Responsive padding
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Berakhir',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11, // Responsive font size
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Decorative elements (adjusted for responsiveness)
          Positioned(
            top: isSmallScreen ? -20 : -30,
            right: isSmallScreen ? -20 : -30,
            child: Container(
              width: isSmallScreen ? 70 : 80,
              height: isSmallScreen ? 70 : 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: isSmallScreen ? -25 : -40,
            left: isSmallScreen ? -25 : -40,
            child: Container(
              width: isSmallScreen ? 90 : 100,
              height: isSmallScreen ? 90 : 100,
              decoration: BoxDecoration(
                color: (promo['colors'][0] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePromoSection(bool isSmallScreen) {
    final activePromos = _promoList.where((promo) => promo['isActive']).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Aktif',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22, // Responsive font size
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
        ...activePromos.map((promo) => _buildPromoCard(promo, isSmallScreen)),
      ],
    );
  }

  Widget _buildExpiredPromoSection(bool isSmallScreen) {
    final expiredPromos = _promoList.where((promo) => !promo['isActive']).toList();

    if (expiredPromos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isSmallScreen ? 16 : 20), // Responsive spacing
        Text(
          'Promo Berakhir',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22, // Responsive font size
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
        ...expiredPromos.map((promo) => _buildPromoCard(promo, isSmallScreen)),
      ],
    );
  }

  Widget _buildPromoHeader(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 24 : 32), // Responsive margin
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // Responsive padding
      decoration: BoxDecoration(
        // Changed to red gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade700, // Start red
            Colors.red.shade900, // End red
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24), // Responsive border radius
        border: Border.all(color: Colors.transparent, width: 1), // Border transparent
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3), // Red shadow
            blurRadius: isSmallScreen ? 10 : 20, // Responsive blur
            offset: Offset(0, isSmallScreen ? 4 : 8), // Responsive offset
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
                  'Promo Spesial! 🎉',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color is white
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                Text(
                  'Dapatkan berbagai penawaran menarik untuk perjalanan kereta api Anda',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                    color: Colors.white.withOpacity(0.9), // Text color is white
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16), // Responsive spacing
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // Icon background is white with opacity
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // Responsive border radius
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: isSmallScreen ? 32 : 36, // Responsive icon size
              color: Colors.white, // Icon color is white
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoDetail(BuildContext context, Map<String, dynamic> promo, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // Responsive padding
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: isSmallScreen ? 30 : 40, // Responsive width
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing

            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // Responsive padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: promo['colors']),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
                  ),
                  child: Icon(
                    promo['icon'],
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24, // Responsive icon size
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16), // Responsive spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo['title'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18, // Responsive font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Berlaku hingga: ${promo['validUntil']}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 5 : 6), // Responsive padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: promo['colors']),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // Responsive border radius
                  ),
                  child: Text(
                    promo['discount'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing

            // Description
            Text(
              'Detail Promo',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
            Text(
              promo['description'],
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing

            // Action button
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 45 : 56, // Responsive button height
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Promo "${promo['title']}" telah diterapkan!'),
                      backgroundColor: promo['colors'][0],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: promo['colors'][0],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16), // Responsive padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Gunakan Promo',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16, // Responsive font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 8 : 16), // Responsive spacing
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
        padding: EdgeInsets.fromLTRB(isSmallScreen ? 16.0 : 20.0, isSmallScreen ? 16.0 : 20.0, isSmallScreen ? 16.0 : 20.0, isSmallScreen ? 70.0 : 80.0), // Responsive padding
        children: [
          _buildPromoHeader(isSmallScreen),
          _buildActivePromoSection(isSmallScreen),
          _buildExpiredPromoSection(isSmallScreen),
          SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing
        ],
      ),
    );
  }
}