import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../login/login_screen.dart';
import 'list_gerbong_screen.dart';
import 'list_jadwal_krl_final_screen.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/transaksi_model.dart';
import 'list_user_screen.dart';

// Color constants
const Color charcoalGray = Color(0xFF374151);
const Color darkCharcoal = Color(0xFF1F2937);
const Color electricBlue = Color(0xFF3B82F6);
const Color pureWhite = Color(0xFFFFFFFF);
const Color backgroundGrey = Color(0xFFF9FAFB);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService authService = AuthService();
  String _adminName = "Admin";

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late int _selectedMonth;
  late int _selectedYear;
  String _selectedGraphType = 'Grafik Batang'; // Default graph type
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadAdminName();

    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  void _loadAdminName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _adminName = user.email!.split('@')[0];
      });
    }
  }

  // --- MODIFIKASI DIMULAI DI SINI ---
  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "Kelola Stasiun",
      "icon": Icons.account_balance_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListStasiunScreen()),
        );
      },
    },
    {
      "title": "Kelola Tipe Gerbong",
      "icon": Icons.view_comfortable_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListGerbongScreen()),
        );
      },
    },
    {
      "title": "Kelola Kereta",
      "icon": Icons.train_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListKeretaScreen()),
        );
      },
    },
    {
      "title": "Kelola Jadwal",
      "icon": Icons.calendar_today_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListJadwalScreen()),
        );
      },
    },
    {
      "title": "Kelola Jadwal KRL",
      "icon": Icons.schedule,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListJadwalKrlFinalScreen()),
        );
      },
    },
    {
      "title": "Kelola User",
      "icon": Icons.people_alt_outlined,
      "onTap": (BuildContext context) {
        // Awalnya: Navigasi ke ListUserScreen
        // Navigator.push(
        //    context,
        //    MaterialPageRoute(builder: (context) => const ListUserScreen()),
        //  );

        // Diubah menjadi: Tampilkan notifikasi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur dinonaktifkan sementara karena kendala teknis.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      },
    }
  ];
  // --- MODIFIKASI SELESAI DI SINI ---

  Stream<List<TransaksiModel>> _getMonthlySalesStream(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    return _db
        .collection('transaksi')
        .where('tanggalTransaksi', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('tanggalTransaksi', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransaksiModel.fromFirestore(doc)).toList());
  }

  Stream<List<TransaksiModel>> _getTotalSalesStream() {
    return _db
        .collection('transaksi')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransaksiModel.fromFirestore(doc)).toList());
  }

  List<DropdownMenuItem<int>> _buildMonthDropdownItems() {
    final List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return List.generate(12, (index) {
      return DropdownMenuItem(
        value: index + 1,
        child: Text(monthNames[index]),
      );
    });
  }

  List<DropdownMenuItem<int>> _buildYearDropdownItems() {
    final currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear - 2 + index);
    return years.map((year) {
      return DropdownMenuItem(
        value: year,
        child: Text(year.toString()),
      );
    }).toList();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: charcoalGray,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: charcoalGray,
            foregroundColor: pureWhite,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: pureWhite,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [charcoalGray, darkCharcoal],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 20,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 100,
                        color: pureWhite.withAlpha((255 * 0.2).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                color: pureWhite,
                onPressed: () async {
                  final confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Konfirmasi Keluar"),
                      content: const Text("Anda yakin ingin keluar dari akun admin?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirmLogout == true && context.mounted) {
                    await authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginEmailScreen()),
                          (Route<dynamic> route) => false,
                    );
                  }
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Welcome Section
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.05).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: electricBlue.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: electricBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat Datang!",
                              style: TextStyle(
                                fontSize: 14,
                                color: charcoalGray.withAlpha((255 * 0.7).round()),
                              ),
                            ),
                            Text(
                              _adminName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: charcoalGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Menu Kelola",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: charcoalGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: _buildAdminMenuItem(
                                context,
                                title: item["title"],
                                icon: item["icon"],
                                onTap: () => item["onTap"](context),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Total Sales Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSectionHeader("Total Penjualan Tiket Seluruhnya"),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<List<TransaksiModel>>(
                    stream: _getTotalSalesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: electricBlue));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      final totalSales = snapshot.data?.fold<int>(0, (sum, item) => sum + item.totalBayar) ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [electricBlue, electricBlue.withAlpha((255 * 0.8).round())],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: electricBlue.withAlpha((255 * 0.3).round()),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Grand Total",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: pureWhite.withAlpha((255 * 0.9).round()),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormatter.format(totalSales),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: pureWhite,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: pureWhite.withAlpha((255 * 0.2).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: pureWhite,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Monthly Sales Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSectionHeader("Penjualan Tiket Per Bulan"),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: electricBlue.withAlpha((255 * 0.3).round())),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: "Bulan",
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: charcoalGray),
                            ),
                            dropdownColor: pureWhite,
                            items: _buildMonthDropdownItems(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedMonth = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: electricBlue.withAlpha((255 * 0.3).round())),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              labelText: "Tahun",
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: charcoalGray),
                            ),
                            dropdownColor: pureWhite,
                            items: _buildYearDropdownItems(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedYear = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Monthly Revenue Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSectionHeader(
                      "Total Pendapatan Bulan " + DateFormat('MMMM', 'id_ID').format(DateTime(_selectedYear, _selectedMonth))),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<List<TransaksiModel>>(
                    stream: _getMonthlySalesStream(_selectedYear, _selectedMonth),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: electricBlue));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      final monthlyTotalRevenue = snapshot.data?.fold<int>(0, (sum, item) => sum + item.totalBayar) ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.05).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currencyFormatter.format(monthlyTotalRevenue),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: electricBlue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Graph Type Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: electricBlue.withAlpha((255 * 0.3).round())),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedGraphType,
                      decoration: const InputDecoration(
                        labelText: "Tampilan",
                        border: InputBorder.none,
                        labelStyle: TextStyle(color: charcoalGray),
                      ),
                      dropdownColor: pureWhite,
                      items: const [
                        DropdownMenuItem(value: 'Grafik Batang', child: Text('Grafik Batang')),
                        DropdownMenuItem(value: 'Grafik Garis', child: Text('Grafik Garis')),
                        DropdownMenuItem(value: 'Tabel Data', child: Text('Tabel Data')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGraphType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Charts/Table Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<List<TransaksiModel>>(
                    stream: _getMonthlySalesStream(_selectedYear, _selectedMonth),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: electricBlue));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              "Tidak ada data penjualan untuk periode ini.",
                              style: TextStyle(color: charcoalGray),
                            ),
                          ),
                        );
                      }

                      final monthlySales = snapshot.data!;
                      final Map<String, double> dailySales = {};

                      for (var transaction in monthlySales) {
                        final date = DateFormat('dd MMM').format(transaction.tanggalTransaksi.toDate());
                        dailySales.update(date, (value) => value + transaction.totalBayar, ifAbsent: () => transaction.totalBayar.toDouble());
                      }

                      final sortedDailySales = dailySales.entries.toList()
                        ..sort((a, b) {
                          final dateFormat = DateFormat('dd MMM');
                          final dateA = dateFormat.parse(a.key + ' ' + _selectedYear.toString());
                          final dateB = dateFormat.parse(b.key + ' ' + _selectedYear.toString());
                          return dateA.compareTo(dateB);
                        });

                      final maxSales = sortedDailySales.isEmpty ? 0.0 : sortedDailySales.map((e) => e.value).reduce((a, b) => a > b ? a : b);

                      return Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.05).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedGraphType == 'Grafik Batang' ? "Grafik Penjualan Harian" :
                              _selectedGraphType == 'Grafik Garis' ? "Grafik Garis Penjualan Harian" :
                              "Tabel Data Penjualan Harian",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: charcoalGray,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _selectedGraphType == 'Grafik Batang'
                                ? SizedBox(
                              height: 220,
                              child: sortedDailySales.isEmpty
                                  ? const Center(child: Text("Tidak ada data penjualan untuk periode ini."))
                                  : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: sortedDailySales.length,
                                itemBuilder: (context, index) {
                                  final entry = sortedDailySales[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormatter.format(entry.value),
                                          style: const TextStyle(fontSize: 10, color: charcoalGray),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 24,
                                          height: maxSales > 0 ? (entry.value / maxSales) * 140 : 0,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [electricBlue, electricBlue.withAlpha((255 * 0.7).round())],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(fontSize: 10, color: charcoalGray),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                                : _selectedGraphType == 'Grafik Garis'
                                ? SizedBox(
                              height: 220,
                              child: sortedDailySales.isEmpty
                                  ? const Center(child: Text("Tidak ada data penjualan untuk periode ini."))
                                  : CustomPaint(
                                painter: LineGraphPainter(
                                  data: sortedDailySales,
                                  maxValue: maxSales,
                                  lineColor: electricBlue,
                                ),
                                size: Size.infinite,
                              ),
                            )
                                : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(electricBlue.withAlpha((255 * 0.1).round())),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Tanggal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: charcoalGray,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total Penjualan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: charcoalGray,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: sortedDailySales.map((entry) {
                                  return DataRow(cells: [
                                    DataCell(Text(entry.key, style: const TextStyle(color: charcoalGray))),
                                    DataCell(Text(
                                      currencyFormatter.format(entry.value),
                                      style: const TextStyle(
                                        color: electricBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Container(
      width: 130,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.05).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: electricBlue.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: electricBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: charcoalGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Line Graph Painter (you'll need to implement this if not already available)
class LineGraphPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final Color lineColor;

  LineGraphPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (data[i].value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw points
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
