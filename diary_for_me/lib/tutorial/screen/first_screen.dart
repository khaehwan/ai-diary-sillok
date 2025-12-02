import 'package:flutter/material.dart';
import 'profile_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 사관 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'lib/common/resource/first_screen.png',
                    width: 256,
                    height: 256,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),

                // 제목: 로고
                ClipRRect(
                  child: Image.asset(
                    'lib/common/resource/logo.png',
                    width: 128,
                    height: 44,
                  ),
                ),
                const SizedBox(height: 8),

                // 부제목
                const Text(
                  '당신의 하루를 기록해주는\nAI 사관을 만나보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xA3111111),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // 시작하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // 버튼을 눌렀을 때 ProfileScreen으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8d6ce9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: const Color(0xFF8d6ce9),
                      elevation: 8,
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
