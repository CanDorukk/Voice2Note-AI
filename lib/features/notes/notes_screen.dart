import 'package:flutter/material.dart';

/// Not listesi ekranı. Splash'ten "Başla" sonrası açılır.
/// Henüz liste mantığı yok, sadece iskelet.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
      ),
      body: const Center(
        child: Text('Henüz not yok. Kayıt ekranı eklenecek.'),
      ),
    );
  }
}
