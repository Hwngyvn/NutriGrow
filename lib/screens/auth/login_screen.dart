import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  Future<void> loginUser() async {

    try {

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message =
          "Login gagal";

      if (e.code == "user-not-found") {
        message =
            "Email tidak ditemukan";
      }

      if (e.code == "wrong-password" ||
          e.code == "invalid-credential") {
        message =
            "Password salah";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 40),

              Center(
                child: Image.asset(
                  'assets/images/NutriGrow_Logo_App_Icon.png',
                  width: 100,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Selamat Datang",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Masuk untuk memantau tumbuh kembang anak",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                "Email",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              CustomTextField(
                controller: emailController,
                hint: "Masukkan email",
              ),

              const SizedBox(height: 20),

              const Text(
                "Password",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,

                decoration: InputDecoration(
                  hintText: "Masukkan password",

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: "Masuk",

                onPressed: () async {
                  await loginUser();
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [

                  const Expanded(
                    child: Divider(),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 10),
                    child: Text(
                      "atau",
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Divider(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: OutlinedButton.icon(
                  onPressed: () {},

                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 28,
                  ),

                  label: const Text(
                    "Masuk dengan Google",
                  ),

                  style: OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Text(
                    "Belum punya akun?",
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegisterScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Daftar",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}