import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/chat_message.dart';
import '../../../../services/gemini_cloud_function_service.dart';
import '../../../../widgets/message_bubble.dart';
import '../../../../widgets/message_input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Jika pengguna tidak login, tampilkan pesan peringatan
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: 'Anda harus login untuk menggunakan dan menyimpan riwayat chat AI.',
        isFromUser: false,
        isError: true,
      ));
    } else {
      _loadChatHistory();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadChatHistory() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('gemini_chat_history')
          .orderBy('timestamp', descending: true) // Urutkan dari terbaru ke terlama
          .limit(20) // Ambil 20 pesan terakhir
          .get();

      final loadedMessages = chatSnapshot.docs.reversed.map((doc) { // Balik urutan agar dari terlama ke terbaru
        return ChatMessage(
          id: doc.id,
          text: doc['text'] as String,
          isFromUser: doc['sender'] == 'user',
          isError: doc['isError'] ?? false,
        );
      }).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(loadedMessages);
      });
      _scrollDown();
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text: 'Gagal memuat riwayat chat.',
          isFromUser: false,
          isError: true,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveMessageToFirestore(ChatMessage message) {
    if (_currentUser == null) return;

    _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('gemini_chat_history')
        .add({
      'sender': message.isFromUser ? 'user' : 'gemini',
      'text': message.text,
      'timestamp': FieldValue.serverTimestamp(), // Timestamp dari server Firestore
      'isError': message.isError,
    })
        .then((docRef) {
      // Opsional: perbarui ID pesan lokal dengan ID Firestore jika perlu
      // int index = _messages.indexWhere((msg) => msg.id == message.id);
      // if (index != -1) {
      //   _messages[index] = ChatMessage(
      //     id: docRef.id,
      //     text: message.text,
      //     isFromUser: message.isFromUser,
      //     isTyping: message.isTyping,
      //     isError: message.isError,
      //   );
      // }
    })
        .catchError((error) => print("Failed to add message to Firestore: $error"));
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk chat dengan AI.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_textController.text.isEmpty) return;

    final userMessageText = _textController.text;
    _textController.clear();
    FocusScope.of(context).unfocus(); // Tutup keyboard

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: userMessageText,
      isFromUser: true,
    );

    setState(() {
      _isLoading = true;
      _messages.add(userMessage);
      _scrollDown();

      // Tambahkan indikator 'typing' dari AI
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '...',
        isFromUser: false,
        isTyping: true,
      ));
      _scrollDown();
    });

    _saveMessageToFirestore(userMessage); // Simpan pesan pengguna

    try {
      final responseText = await _geminiService.sendMessage(userMessageText);
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isFromUser: false,
      );

      setState(() {
        // Hapus indikator 'typing'
        _messages.removeWhere((msg) => msg.isTyping);
        // Tambahkan respons AI
        _messages.add(aiMessage);
      });
      _saveMessageToFirestore(aiMessage); // Simpan respons AI
    } catch (e) {
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text: 'Maaf, terjadi kesalahan. Coba lagi.\nDetail: ${e.toString()}',
        isFromUser: false,
        isError: true,
      );
      setState(() {
        // Hapus indikator 'typing'
        _messages.removeWhere((msg) => msg.isTyping);
        // Tambahkan pesan error
        _messages.add(errorMessage);
      });
      _saveMessageToFirestore(errorMessage); // Simpan pesan error
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan tema yang sudah ada di aplikasi Anda
    final appBarColor = const Color(0xFFC50000); // Dari AppBar di screens lain
    final primaryColor = Theme.of(context).primaryColor; // Dari main.dart Theme

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan AI'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Tombol kembali (jika diperlukan, sesuai navigasi)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          MessageInputBar(
            controller: _textController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}