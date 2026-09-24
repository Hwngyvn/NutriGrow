import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/profile/profile_child_screen.dart';
import '../../utils/colors.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/monitoring/monitoring_screen.dart';
import '../../screens/nutrition/nutrition_input_screen.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  String? userName;
  String? userEmail;
  String? activeChildId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadActiveChild();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      userName = userDoc.data()?["name"] ?? user.displayName ?? "Pengguna";
      userEmail = user.email ?? "Tidak ada email";
    });
  }

  Future<void> _loadActiveChild() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      activeChildId = prefs.getString('activeChildId_${user.uid}');
    });
  }

  Future<void> _selectChild(String childId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeChildId_${user.uid}', childId);

    if (!mounted) return; 

    setState(() {
      activeChildId = childId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Anak aktif berhasil dipilih"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          AppColors.background,

      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;

          Widget destination;
          switch (index) {
            case 0:
              destination = const DashboardScreen();
              break;
            case 1:
              destination = activeChildId == null
                  ? const ProfileChildScreen()
                  : const NutritionInputScreen();
              break;
            case 2:
              destination = activeChildId == null
                  ? const ProfileChildScreen()
                  : const MonitoringScreen();
              break;
            default:
              return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),

      appBar: AppBar(
        title: const Text("Profil Anak"),
        backgroundColor:
            AppColors.primary,

        actions: [

          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {

              showDialog(
                context: context,
                builder: (context) {

                  return AlertDialog(
                    title: const Text(
                      "Logout",
                    ),
                    content: const Text(
                      "Apakah Anda yakin ingin keluar?",
                    ),
                    actions: [

                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                              context);
                        },
                        child:
                            const Text(
                          "Batal",
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          final currentContext = context;

                          await FirebaseAuth.instance.signOut();

                          if (mounted) {
                            Navigator.pushReplacement(
                              currentContext,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(),
                              ),
                            );
                          }
                        },
                        child:
                            const Text(
                          "Logout",
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
            label: const Text(
              "Logout",
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // Profile Header
            Container(
              padding:
                  const EdgeInsets.all(
                      20),

              decoration:
                  BoxDecoration(
                color: AppColors
                    .darkGreenCard,

                borderRadius:
                    BorderRadius
                        .circular(
                            20),
              ),

              child: Row(
                children: [

                  const CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Colors.white,
                    child: Icon(
                      Icons
                          .child_friendly,
                      size: 40,
                      color: AppColors
                          .primary,
                    ),
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        Text(
                          userName ?? "Pengguna",

                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white,

                            fontSize: 20,

                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                            height: 5),

                        Text(
                          userEmail ?? "",

                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              "Profil Anak",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildChildrenList(),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text("Tambah Profil Anak"),
              trailing: const Icon(Icons.chevron_right),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileChildScreen()),
                );

                await _loadActiveChild();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("children")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Gagal memuat daftar anak",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final children = snapshot.data?.docs ?? [];

        if (children.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Belum ada profil anak. Tambahkan profil anak terlebih dahulu.",
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return Column(
          children: children.map((doc) {
            final data = doc.data();
            final isActive = doc.id == activeChildId;
            final name = data["childName"] ?? "Anak";
            final age = data["age"]?.toString() ?? "-";
            final gender = data["gender"] ?? "-";
            final activity = data["activity"] ?? "Sedang";

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.child_care,
                    color: isActive
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text("$age tahun - $gender"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Edit profil anak",
                      icon: const Icon(Icons.edit),
                      color: AppColors.primary,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileChildScreen(
                              childId: doc.id,
                              initialName: name,
                              initialAge: int.tryParse(age),
                              initialActivity: activity,
                            ),
                          ),
                        );

                        await _loadActiveChild();
                      },
                    ),
                    isActive
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _selectChild(doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}