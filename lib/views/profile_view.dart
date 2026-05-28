import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'edit_profile_view.dart';
import './signin_view.dart';
import '../models/memory.dart';
import '../service/memory_service.dart';
import '../utils/app_image.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback onBackToHome;
  const ProfileView({super.key, required this.onBackToHome});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'Deleting your account will remove your profile document from SnapDate and sign you out permanently. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() => _isDeleting = true);

    final isGoogleUser = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    try {
      if (isGoogleUser) {
        await _reauthenticateGoogleUser();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await GoogleSignIn().signOut();
      await user.delete();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInView()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is FirebaseAuthException &&
              error.code == 'requires-recent-login'
          ? 'Please sign in again before deleting your account.'
          : 'Could not delete account: $error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _reauthenticateGoogleUser() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Could not authenticate with Google.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(
      credential,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dynamically listen to the Auth State so we always have the fresh UID
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // If no user is logged in, gracefully navigate them back out
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text("No user logged in.")),
          );
        }

        // 2. Use the verified UID to fetch the Firestore document stream
        return Scaffold(
          backgroundColor: Colors.white,
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, firestoreSnapshot) {
              if (firestoreSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String username = user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : "Anonymous User";
              String avatarUrl = "";
              String bio = "";

              if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
                final data =
                    firestoreSnapshot.data!.data() as Map<String, dynamic>;
                final savedUsername = data['username']?.toString().trim();
                if (savedUsername != null && savedUsername.isNotEmpty) {
                  username = savedUsername;
                }
                avatarUrl =
                    (data['profileImageUrl'] ??
                            data['avatarUrl'] ??
                            data['profileImagePath'] ??
                            "")
                        .toString();
                bio = (data['bio'] ?? '').toString();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFFCD7D9),
                      child: avatarUrl.trim().isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black54,
                            )
                          : ClipOval(
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: appImage(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  fallback: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      username,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 25),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Memories",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _MemoryStrip(
                      stream: MemoryService().streamMemories(
                        user.uid,
                        limit: 4,
                      ),
                      emptyText: 'No memories yet.',
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Favorites",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MemoryStrip(
                      stream: MemoryService().streamFavorites(user.uid),
                      emptyText: 'No favorites yet.',
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileView(
                            currentUsername: username,
                            currentAvatar: avatarUrl,
                            currentBio: bio,
                          ),
                        ),
                      ),
                      child: const Text("EDIT PROFILE"),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isDeleting
                          ? null
                          : () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignInView(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                      child: const Text(
                        "LOG OUT",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      onPressed: _isDeleting ? null : _handleDeleteAccount,
                      child: _isDeleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.redAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "DELETE ACCOUNT",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MemoryStrip extends StatelessWidget {
  final Stream<List<Memory>> stream;
  final String emptyText;

  const _MemoryStrip({required this.stream, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Memory>>(
      stream: stream,
      builder: (context, snapshot) {
        final memories = (snapshot.data ?? []).take(4).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (memories.isEmpty) {
          return Container(
            height: 94,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF6F4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(color: Colors.black38),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: memories.length,
          itemBuilder: (ctx, index) {
            final memory = memories[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                color: const Color(0xFFEDF6F4),
                child: memory.type == MemoryType.image
                    ? appImage(
                        memory.mediaUrl,
                        fit: BoxFit.cover,
                        fallback: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.black12,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.black38,
                          size: 42,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
