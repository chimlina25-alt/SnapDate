import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  final VoidCallback onBackToHome;
  const CalendarView({super.key, required this.onBackToHome});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _selectedDate = DateTime.now();
  String _activeTabMode = 'Day'; // Default interval selection tab tracker
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  void _shiftTime(int step) {
    setState(() {
      if (_activeTabMode == 'Day') {
        _selectedDate = _selectedDate.add(Duration(days: step));
      } else if (_activeTabMode == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + step, _selectedDate.day);
      } else {
        _selectedDate = DateTime(_selectedDate.year + step, _selectedDate.month, _selectedDate.day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String dateStringKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Upper Mode Switch Tab Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Day', 'Month', 'Year'].map((tabLabel) {
                final isSelected = _activeTabMode == tabLabel;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabMode = tabLabel),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD6A2A8) : const Color(0xFFEDF6F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabLabel,
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Horizontal Sequence Arrow Increment Ribbon Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftTime(-1)),
                  Text(
                    _activeTabMode == 'Day'
                        ? DateFormat('EEEE, d, MMMM, yyyy').format(_selectedDate)
                        : _activeTabMode == 'Month'
                            ? DateFormat('MMMM, yyyy').format(_selectedDate)
                            : DateFormat('yyyy').format(_selectedDate),
                    style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftTime(1)),
                ],
              ),
            ),
          ),

          // Core Real-Time Timeline Database Grid Builder Canvas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .collection('memories')
                  .where('dateGroup', isEqualTo: dateStringKey)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyPlaceholder();

                final docs = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(image: NetworkImage(data['imageUrl'] ?? ''), fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text("No memories logged for this time scope.", style: TextStyle(color: Colors.black38, fontFamily: 'Georgia')),
        ],
      ),
    );
  }
}