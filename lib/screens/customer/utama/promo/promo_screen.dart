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

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: promo['colors'],
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: promo['colors'][0].withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: promo['isActive'] ? () {
                  _showPromoDetail(promo);
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              promo['icon'],
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((255 * 0.9).round()),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              promo['discount'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: promo['colors'][0],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        promo['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha((255 * 0.9).round()),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Berlaku hingga: ${promo['validUntil']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha((255 * 0.8).round()),
                            ),
                          ),
                          if (!promo['isActive'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha((255 * 0.2).round()),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withAlpha((255 * 0.5).round())),
                              ),
                              child: const Text(
                                'Berakhir',
                                style: TextStyle(
                                  fontSize: 11,
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
          // Decorative elements
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((255 * 0.1).round()),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePromoSection() {
    final activePromos = _promoList.where((promo) => promo['isActive']).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Aktif',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...activePromos.map((promo) => _buildPromoCard(promo)),
      ],
    );
  }

  Widget _buildExpiredPromoSection() {
    final expiredPromos = _promoList.where((promo) => !promo['isActive']).toList();
    
    if (expiredPromos.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Promo Berakhir',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...expiredPromos.map((promo) => _buildPromoCard(promo)),
      ],
    );
  }

  Widget _buildPromoHeader() {
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
                  'Promo Spesial! 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dapatkan berbagai penawaran menarik untuk perjalanan kereta api Anda',
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
              Icons.local_offer_rounded,
              size: 36,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoDetail(Map<String, dynamic> promo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: promo['colors']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    promo['icon'],
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
                        promo['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Berlaku hingga: ${promo['validUntil']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: promo['colors']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promo['discount'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              'Detail Promo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              promo['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action button
            SizedBox(
              width: double.infinity,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Gunakan Promo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
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
        children: [
          _buildPromoHeader(),
          _buildActivePromoSection(),
          _buildExpiredPromoSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}