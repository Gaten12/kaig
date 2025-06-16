// gaten12/kaig/kaig-604cabb618ed798f94355f460a3f7be65fa71320/lib/screens/admin/screens/sales_statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({super.key});

  @override
  State<SalesStatisticsScreen> createState() => _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState extends State<SalesStatisticsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late int _selectedMonth;
  late int _selectedYear;
  String _selectedGraphType = 'Grafik Batang'; // Default graph type

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

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

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Statistik Penjualan Tiket",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Total Penjualan Tiket Seluruhnya"),
            const SizedBox(height: 12),
            StreamBuilder<List<TransaksiModel>>(
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
            const SizedBox(height: 32),

            _buildSectionHeader("Penjualan Tiket Per Bulan"),
            const SizedBox(height: 12),
            Row(
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
            const SizedBox(height: 24),
            // Total Pendapatan Per Bulan
            StreamBuilder<List<TransaksiModel>>(
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
                        Text(
                          "Total Pendapatan Bulan " + DateFormat('MMMM yyyy', 'id_ID').format(DateTime(_selectedYear, _selectedMonth)),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        Text(
                          currencyFormatter.format(monthlyTotalRevenue),
                          style: TextStyle(
                            fontSize: 20,
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
            const SizedBox(height: 24),
            // Graph/Table Type Selector
            Row(
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
            const SizedBox(height: 24),
            StreamBuilder<List<TransaksiModel>>(
              stream: _getMonthlySalesStream(_selectedYear, _selectedMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data penjualan untuk bulan ini."));
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
          ],
        ),
      ),
    );
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
}

// Custom Painter for drawing the line graph
class LineGraphPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final Color lineColor;

  LineGraphPainter({required this.data, required this.maxValue, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.fill;

    final path = Path();

    // Calculate scaling factors
    final double xStep = size.width / (data.length > 1 ? data.length - 1 : 1);
    final double yMax = size.height;

    // Draw lines and points
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double y = yMax - (data[i].value / (maxValue > 0 ? maxValue : 1)) * yMax; // Avoid division by zero

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is LineGraphPainter &&
        (oldDelegate.data != data || oldDelegate.maxValue != maxValue || oldDelegate.lineColor != lineColor);
  }
}