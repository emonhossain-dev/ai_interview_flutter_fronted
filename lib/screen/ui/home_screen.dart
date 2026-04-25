import 'package:ai_interview/utils/pathclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(

            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ================= HEADER =================
                    Column(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: SvgPicture.asset(
                                Pathclass.bg_home_head,
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 2,
                                          ),
                                        ),
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Icon(Icons.person, color: Colors.black),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Welcome back", style: TextStyle(color: Colors.grey)),
                                          Text("Alex Carter",
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text("Software Engineer Candidate",
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.notifications, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ================= CARD HEIGHT PLACEHOLDER =================
                        SizedBox(height: 300), // card er height + top offset
                      ],
                    ),

                    // ================= OVERLAPPING CARD =================
                    Positioned(
                      top: 150,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: const Color(0xFF121927),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(
                            children: [
                              // Glow effect
                              Positioned(
                                top: -50,
                                right: -40,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF747145).withOpacity(0.6),
                                        const Color(0xFF747145).withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Daily Goal Badge
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF1E2A3A),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("⚡", style: TextStyle(fontSize: 16)),
                                            SizedBox(width: 6),
                                            Text("Daily Goal: 1/3",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Text("Ready for your\nnext mock?",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text("Continue your System Design\npractice track",
                                        style: TextStyle(color: Colors.white60, fontSize: 16),
                                      ),
                                      SizedBox(height: 16),
                                      // Start Interview Button
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFFCC00),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_arrow, color: Colors.black, size: 28),
                                            SizedBox(width: 10),
                                            Text("Start Interview",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ================= YOUR PROGRESS (STATS) =================
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your Progress",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          // Total Interviews
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.videocam, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text("12",
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  Text("Total Interviews",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Avg Score
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.star, color: Colors.green),
                                  SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(text: "85",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(text: "/100",
                                          style: TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text("Avg Score",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // ================= YOUR PROGRESS (CARDS) =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Your Progress",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text("See More",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildCourseCard()),
                          SizedBox(width: 12),
                          Expanded(child: _buildCourseCard()),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              color: Colors.grey[800],
              child: Center(
                child: Icon(Icons.code, color: Colors.white, size: 30),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("100%",
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ),
                SizedBox(height: 6),
                Text("Technical",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text("DSA & Algorithms",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("Start", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}