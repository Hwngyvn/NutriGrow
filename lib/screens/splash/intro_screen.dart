import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../auth/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {

  final PageController _pageController = PageController();

  int currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Pantau Gizi Si Kecil",
      "description":
          "Pantau kebutuhan gizi harian anak dengan mudah dan praktis.",
      "image": "assets/images/NutriGrow_Child_Illustration.png",
    },
    {
      "title": "Hitung Kebutuhan Gizi",
      "description":
          "Perhitungan otomatis berdasarkan usia, berat badan dan aktivitas.",
      "image": "assets/images/NutriGrow_Child_Illustration.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: PageView.builder(
                controller: _pageController,

                itemCount: pages.length,

                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },

                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(30),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Image.asset(
                          pages[index]["image"]!,
                          height: 280,
                        ),

                        const SizedBox(height: 40),

                        Text(
                          pages[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          pages[index]["description"]!,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: List.generate(
                pages.length,
                (index) => Container(
                  margin:
                      const EdgeInsets.symmetric(
                          horizontal: 5),

                  width: currentPage == index
                      ? 25
                      : 8,

                  height: 8,

                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? AppColors.primary
                        : Colors.grey,

                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 25),

              child: SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: () {

                    if (currentPage ==
                        pages.length - 1) {

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(),
                        ),
                      );
                    } else {

                      _pageController.nextPage(
                        duration:
                            const Duration(
                                milliseconds:
                                    300),
                        curve:
                            Curves.easeInOut,
                      );
                    }
                  },

                  child: Text(
                    currentPage ==
                            pages.length - 1
                        ? "Mulai"
                        : "Selanjutnya",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}