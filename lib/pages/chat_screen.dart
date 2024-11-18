import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userMessage = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isWifiConnected = false;
  bool _isListening = false;

  static const apiKey = "api-key";
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  List<Message> _messages = [];

  // Speech-to-text and Text-to-speech
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _configureTts();
    _checkWifiConnection();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _loadMessages();
  }

  Future<void> _initializeSpeechToText() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      print('Speech recognition no está disponible.');
    }
  }

  Future<void> _configureTts() async {
    if (Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
      );
    }
    if (Platform.isAndroid) {
      await _flutterTts.setSpeechRate(0.5); // Configuración adicional para Android
    }
  }

  Future<void> _checkWifiConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isWifiConnected = result == ConnectivityResult.wifi;
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMessages = prefs.getString('chat_messages');

    if (savedMessages != null) {
      setState(() {
        _messages = (json.decode(savedMessages) as List)
            .map((data) => Message.fromJson(data))
            .toList();
      });
      _scrollToBottom(); // Asegura que el scroll esté abajo al cargar mensajes
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedMessages = json.encode(_messages.map((msg) => msg.toJson()).toList());
    await prefs.setString('chat_messages', encodedMessages);
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return; // Validación adicional
    setState(() {
      _messages.add(Message(isUser: true, message: message, date: DateTime.now()));
    });

    _saveMessages();
    _scrollToBottom(); // Mueve el scroll hacia abajo

    try {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);

      final botMessage = response.text ?? "Lo siento, no pude entender eso.";

      setState(() {
        _messages.add(Message(
          isUser: false,
          message: botMessage,
          date: DateTime.now(),
        ));
      });

      _scrollToBottom(); // Asegura que el scroll esté abajo al recibir respuesta
      await _speak(botMessage); // Lee en voz alta la respuesta del chatbot
      _saveMessages();
    } catch (e) {
      print("Error enviando mensaje: $e");
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error al reproducir audio: $e");
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            final recognizedWords = result.recognizedWords;
            if (result.finalResult && recognizedWords.isNotEmpty) {
              _speechToText.stop();
              setState(() => _isListening = false);
              _userMessage.text = recognizedWords;
              sendMessage(recognizedWords); // Envía automáticamente el mensaje
            }
          },
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Villo Chat Bot'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Messages(
                  isUser: message.isUser,
                  message: message.message,
                  date: DateFormat('HH:mm').format(message.date),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                Expanded(
                  flex: 15,
                  child: TextFormField(
                    controller: _userMessage,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      label: const Text("¿Qué deseas saber?"),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.all(15),
                  iconSize: 20,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        _isWifiConnected ? Colors.black : Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    shape: MaterialStateProperty.all(const CircleBorder()),
                  ),
                  onPressed: _isWifiConnected
                      ? () {
                          final message = _userMessage.text;
                          if (message.isNotEmpty) {
                            sendMessage(message);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 15).copyWith(
        left: isUser ? 100 : 10,
        right: isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? const Color.fromARGB(255, 35, 110, 171)
            : const Color.fromARGB(183, 50, 173, 244),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(8),
          bottomLeft: isUser ? const Radius.circular(8) : Radius.zero,
          topRight: const Radius.circular(8),
          bottomRight: isUser ? Radius.zero : const Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
          Text(
            date,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      isUser: json['isUser'],
      message: json['message'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'message': message,
      'date': date.toIso8601String(),
    };
  }
}
