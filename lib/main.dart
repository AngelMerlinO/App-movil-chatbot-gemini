import 'package:flutter/material.dart';
import 'package:chatinteractivo/pages/chat_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat Bot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
