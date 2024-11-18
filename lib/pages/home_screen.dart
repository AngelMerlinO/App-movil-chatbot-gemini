import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _launchURL() async {
    const url = 'https://github.com/Villo29/ChatInteractivo.git';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir el enlace: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/logo.jpg', // Ruta correcta
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Gemini Chat Bot',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Carrera: Ingeniería en Desarrollo de Software',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Materia: Móviles II',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Grupo: 9B',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Alumno: Jesus David Ruiz García',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Matrícula: 221263',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _launchURL,
                child: const Text(
                  'Enlace al Repositorio',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
