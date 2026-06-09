import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

class JBAssistantScreen extends StatefulWidget {
  const JBAssistantScreen({super.key});

  @override
  State<JBAssistantScreen> createState() => _JBAssistantScreenState();
}

class _JBAssistantScreenState extends State<JBAssistantScreen> {
  bool isListening = false;
  String status = "Tap the microphone";

  void toggleListening() {
    setState(() {
      isListening = !isListening;
      status = isListening
          ? "Listening..."
          : "Tap the microphone";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("JB Assistant"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          AvatarGlow(
            animate: isListening,
            glowColor: Colors.blue,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: const Icon(
                Icons.graphic_eq,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "Say commands like Play Music, Pause Song, Next Track",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: toggleListening,
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}