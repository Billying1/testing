import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SlashPage extends StatefulWidget {
  const SlashPage({super.key});

  @override
  State<SlashPage> createState() => _SlashPageState();
}

class _SlashPageState extends State<SlashPage> {
  double progress = 0;
  Timer? timer;
  bool isNavigated = false;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        progress += 0.02; // 50 lần = 5 giây
      });

      if (progress >= 1) {
        t.cancel();
        goToLogin();
      }
    });
  }

  void goToLogin() {
    if (isNavigated) return;

    isNavigated = true;
    timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB7F2A1), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.electric_car,
                    size: 100,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Electric Charging Station',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Find and manage EV charging stations',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  const SizedBox(height: 50),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2E7D32),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${(progress * 100).toInt()} %",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: 180,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: goToLogin,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Tiếp tục"),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Hoặc chờ 5 giây để tự động chuyển...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
