import 'package:flutter/material.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  // Helper widget untuk membuat judul bagian
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87, // Sedikit penyesuaian warna agar lebih jelas
        ),
      ),
    );
  }

  // Helper widget untuk membuat konten paragraf
  Widget _buildParagraph(String text, {bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16.0 : 0),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5, // Jarak antar baris agar mudah dibaca
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Tombol kembali berwarna putih
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Judul AppBar sesuai gambar
        title: Center(
          child: const Text(
            "Tentang Aplikasi",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Warna AppBar sesuai gambar
        backgroundColor: const Color(0xFFB71C1C),
        // Menghilangkan bayangan di bawah AppBar
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "KEBIJAKAN PRIVASI",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildSectionTitle("1. TENTANG APLIKASI"),
              _buildParagraph(
                "TrainOrder adalah sebuah platform aplikasi seluler yang bertujuan untuk memudahkan pengguna dalam melakukan pencarian jadwal, pemesanan, pembayaran, dan pengelolaan tiket kereta api di seluruh Indonesia. Misi kami adalah menyediakan proses pemesanan tiket yang cepat, mudah, dan aman langsung dari genggaman Anda."
              ),
              _buildSectionTitle("2. INFORMASI YANG KAMI KUMPULKAN"),
              _buildParagraph(
                "Kami mengumpulkan informasi tentang Anda untuk menyediakan dan meningkatkan layanan kami. Jenis informasi yang kami kumpulkan adalah sebagai berikut:"
              ),
              const SizedBox(height: 12),
              _buildParagraph("a. Data yang Anda Berikan Secara Langsung:", isSubItem: true),
              const SizedBox(height: 8),
              _buildParagraph(
                "Informasi Akun: Saat Anda membuat akun, kami mengumpulkan nama lengkap, alamat email, dan nomor telepon Anda.\n"
                "Informasi Penumpang: Saat Anda memesan tiket, kami mengumpulkan data detail penumpang seperti nama lengkap (sesuai identitas resmi seperti KTP/Paspor), nomor identitas, tanggal lahir, dan jenis kelamin. Data ini diperlukan oleh pihak penyedia layanan kereta api untuk validasi tiket.\n"
                "Informasi Pembayaran: Saat Anda melakukan transaksi, kami mengumpulkan detail terkait pembayaran seperti metode pembayaran yang dipilih. Untuk pembayaran menggunakan kartu kredit/debit, data Anda akan diproses oleh gerbang pembayaran (payment gateway) pihak ketiga kami yang aman dan bersertifikasi. Kami tidak menyimpan detail lengkap kartu kredit Anda di server kami.",
                isSubItem: true
              ),
              const SizedBox(height: 12),
              _buildParagraph("b. Data yang Dikumpulkan Secara Otomatis:", isSubItem: true),
              const SizedBox(height: 8),
              _buildParagraph(
                "Data Perangkat dan Log: Kami secara otomatis mengumpulkan informasi tentang perangkat yang Anda gunakan, seperti alamat IP, jenis sistem operasi, versi aplikasi, dan pengidentifikasi unik perangkat (unique device identifiers).\n"
                "Data Transaksi: Kami mencatat riwayat pemesanan Anda, termasuk stasiun keberangkatan, stasiun tujuan, tanggal perjalanan, dan detail tiket lainnya.",
                isSubItem: true
              ),
              _buildSectionTitle("3. PRIVASI ANAK-ANAK"),
              _buildParagraph(
                "Layanan kami tidak ditujukan untuk individu di bawah usia 18 tahun (\"Anak-anak\") tanpa pengawasan orang tua atau wali. Kami tidak secara sadar mengumpulkan informasi pribadi dari anak-anak. Jika Anda adalah orang tua atau wali dan Anda mengetahui bahwa anak Anda telah memberikan data pribadinya kepada kami tanpa persetujuan Anda, silakan hubungi kami. Jika kami mengetahui bahwa kami telah mengumpulkan data pribadi dari seorang anak tanpa verifikasi persetujuan orang tua, kami akan mengambil langkah-langkah untuk menghapus informasi tersebut dari server kami."
              ),
              _buildSectionTitle("4. AKSES DAN PERUBAHAN DATA PRIBADI"),
              _buildParagraph(
                "Anda memiliki hak untuk mengakses dan memperbarui data pribadi Anda. Anda dapat melihat dan mengubah informasi profil Anda, seperti nama, nomor telepon, dan alamat email, atau penghapusan akun, melalui \"Kelola profil\" pada menu akun saya di dalam aplikasi."
              ),
              _buildSectionTitle("5. PENGGUNAAN COOKIE"),
              _buildParagraph(
                "Aplikasi kami menggunakan \"cookie\" dan teknologi pelacakan serupa (seperti SDK seluler) untuk membedakan Anda dari pengguna lain. Ini membantu kami untuk:\n\n"
                "• Mengingat informasi Anda sehingga Anda tidak perlu memasukkannya kembali.\n"
                "• Memahami bagaimana Anda menggunakan layanan kami untuk dapat meningkatkannya.\n"
                "• Menyediakan pengalaman yang dipersonalisasi.\n\n"
                "Anda dapat mengatur ulang pengaturan perangkat Anda untuk menolak semua cookie, namun hal ini dapat menyebabkan beberapa bagian dari layanan kami tidak berfungsi dengan baik."
              ),
              _buildSectionTitle("6. KEAMANAN DATA PRIBADI ANDA"),
              _buildParagraph(
                "Kami berkomitmen untuk melindungi keamanan data pribadi Anda. Kami menerapkan langkah-langkah keamanan teknis dan organisasi yang sesuai untuk melindungi data pribadi Anda dari akses yang tidak sah, pengungkapan, perubahan, atau penghancuran. Langkah-langkah ini termasuk:\n\n"
                "• Enkripsi: Menggunakan enkripsi (seperti SSL/TLS) untuk melindungi transmisi data.\n"
                "• Kontrol Akses: Membatasi akses ke data pribadi hanya kepada karyawan yang memerlukannya untuk menjalankan tugas mereka.\n"
                "• Mitra Terpercaya: Bekerja sama dengan penyedia layanan pihak ketiga (misalnya, gerbang pembayaran) yang mematuhi standar keamanan yang ketat.\n\n"
                "Meskipun kami berusaha keras untuk melindungi data Anda, perlu diketahui bahwa tidak ada sistem transmisi atau penyimpanan data yang 100% aman."
              ),
              _buildSectionTitle("7. PERSETUJUAN"),
              _buildParagraph(
                "Dengan mendaftar dan menggunakan aplikasi TrainOrder, Anda secara sadar dan sukarela memberikan persetujuan kepada kami untuk mengumpulkan, menggunakan, dan mengungkapkan data pribadi Anda sesuai dengan yang dijelaskan dalam Kebijakan Privasi ini."
              ),
              _buildSectionTitle("8. PENARIKAN PERSETUJUAN"),
              _buildParagraph(
                "Anda berhak untuk menarik kembali persetujuan Anda terhadap pengumpulan dan penggunaan data pribadi Anda kapan saja. Anda dapat melakukannya dengan cara menghubungi kami di [Alamat Email: privacy@trainorder.com].\n\n"
                "Harap diperhatikan bahwa penarikan persetujuan Anda dapat mengakibatkan kami tidak dapat lagi menyediakan layanan kami secara penuh atau sebagian kepada Anda. Misalnya, kami tidak dapat memproses pemesanan tiket tanpa data penumpang yang valid. Penarikan persetujuan tidak akan memengaruhi keabsahan pemrosesan data yang telah kami lakukan sebelum penarikan tersebut."
              ),
              const SizedBox(height: 48),
              const Center(
                child: Text(
                  "© 2025 - Hak Cipta Dilindungi",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}