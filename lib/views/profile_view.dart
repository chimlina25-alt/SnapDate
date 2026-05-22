import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_view.dart';
import './signin_view.dart';

class ProfileView extends StatelessWidget {
  final VoidCallback onBackToHome;
  const ProfileView({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          String username = "Anonymous User";
          String avatarUrl = "";
          List<dynamic> highlights = [];

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? "Anonymous User";
            avatarUrl = data['avatarUrl'] ?? "";
            highlights = data['highlights'] ?? [];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFFCD7D9),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.black54) : null,
                ),
                const SizedBox(height: 12),
                Text(username, style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                
                const Align(alignment: Alignment.centerLeft, child: Text("Highlights", style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: 4,
                  itemBuilder: (ctx, index) {
                    final hasImage = index < highlights.length;
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF6F4),
                        borderRadius: BorderRadius.circular(15),
                        image: hasImage ? DecorationImage(image: NetworkImage(highlights[index]), fit: BoxFit.cover) : null,
                      ),
                      child: !hasImage ? const Center(child: Icon(Icons.photo_library_outlined, color: Colors.black12)) : null,
                    );
                  },
                ),
                const SizedBox(height: 30),
                
               ElevatedButton(
  onPressed: () => Navigator.push(
    context, 
    MaterialPageRoute(
      builder: (_) => EditProfileView(
        currentUsername: username, 
        currentAvatar: avatarUrl, 
        currentHighlights: highlights
      ),
    ),
  ),
  child: const Text("EDIT PROFILE"),
),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInView()), (route) => false);
                  },
                  child: const Text("LOG OUT", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}