import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../profile/profile_child_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmController =
      TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  Future<void> registerUser() async {

    try {

      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          confirmController.text.isEmpty) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Semua data harus diisi",
            ),
          ),
        );

        return;
      }

      if (passwordController.text !=
          confirmController.text) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Password tidak sama",
            ),
          ),
        );

        return;
      }

      final credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email:
            emailController.text.trim(),
        password:
            passwordController.text.trim(),
      );

      await credential.user?.updateDisplayName(
        nameController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set({

        "name":
            nameController.text.trim(),

        "email":
            emailController.text.trim(),

        "createdAt":
            Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileChildScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message =
          "Terjadi kesalahan";

      if (e.code ==
          'email-already-in-use') {
        message =
            "Email sudah digunakan";
      }

      if (e.code ==
          'weak-password') {
        message =
            "Password terlalu lemah";
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 30),

              const Text(
                "Buat Akun",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Daftar untuk mulai memantau gizi anak",
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller:
                    nameController,
                hint:
                    "Nama Lengkap",
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller:
                    emailController,
                hint: "Email",
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                    passwordController,

                obscureText:
                    obscure1,

                decoration:
                    InputDecoration(
                  hintText:
                      "Password",

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            14),
                  ),

                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      obscure1
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        obscure1 =
                            !obscure1;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                    confirmController,

                obscureText:
                    obscure2,

                decoration:
                    InputDecoration(
                  hintText:
                      "Konfirmasi Password",

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            14),
                  ),

                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      obscure2
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        obscure2 =
                            !obscure2;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: "Daftar",

                onPressed: () async {
                  await registerUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
