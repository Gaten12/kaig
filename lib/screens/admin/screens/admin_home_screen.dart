import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/admin_widget.dart';
import '../../login/login_screen.dart';
import 'list_gerbong_screen.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/transaksi_model.dart';


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
    // The "Statistik Penjualan" item is removed from here.
  ];

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
          color: Colors.blueGrey.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Selamat Datang, $_adminName!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            // Sales Statistics content starts here
            const SizedBox(height: 32),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final totalSales = snapshot.data?.fold<int>(0, (sum, item) => sum + item.totalBayar) ?? 0;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Grand Total",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          Text(
                            currencyFormatter.format(totalSales),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

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
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: "Bulan",
                        border: OutlineInputBorder(),
                      ),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: "Tahun",
                        border: OutlineInputBorder(),
                      ),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Total Pendapatan Per Bulan
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final monthlyTotalRevenue = snapshot.data?.fold<int>(0, (sum, item) => sum + item.totalBayar) ?? 0;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Removed the text "Total Pendapatan Bulan ..." from here
                          Text(
                            currencyFormatter.format(monthlyTotalRevenue),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Graph/Table Type Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGraphType,
                      decoration: const InputDecoration(
                        labelText: "Tampilan",
                        border: OutlineInputBorder(),
                      ),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder<List<TransaksiModel>>(
                stream: _getMonthlySalesStream(_selectedYear, _selectedMonth),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Tidak ada data penjualan untuk periode ini."));
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

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedGraphType == 'Grafik Batang' ? "Grafik Penjualan Harian" :
                            _selectedGraphType == 'Grafik Garis' ? "Grafik Garis Penjualan Harian" :
                            "Tabel Data Penjualan Harian",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 16),
                          _selectedGraphType == 'Grafik Batang'
                              ? SizedBox(
                            height: 200,
                            child: sortedDailySales.isEmpty
                                ? const Center(child: Text("Tidak ada data penjualan untuk periode ini."))
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: sortedDailySales.length,
                              itemBuilder: (context, index) {
                                final entry = sortedDailySales[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormatter.format(entry.value),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 20,
                                        height: maxSales > 0 ? (entry.value / maxSales) * 120 : 0,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                              : _selectedGraphType == 'Grafik Garis'
                              ? SizedBox(
                            height: 200,
                            child: sortedDailySales.isEmpty
                                ? const Center(child: Text("Tidak ada data penjualan untuk periode ini."))
                                : CustomPaint(
                              painter: LineGraphPainter(
                                data: sortedDailySales,
                                maxValue: maxSales,
                                lineColor: Theme.of(context).primaryColor,
                              ),
                              size: Size.infinite,
                            ),
                          )
                              : DataTable(
                            columns: const [
                              DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Total Penjualan', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: sortedDailySales.map((entry) {
                              return DataRow(cells: [
                                DataCell(Text(entry.key)),
                                DataCell(Text(currencyFormatter.format(entry.value))),
                              ]);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return Container(
      width: 120,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
