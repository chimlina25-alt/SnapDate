import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_image.dart';
import '../models/memory.dart';
import '../service/memory_service.dart';
import 'media_inspector_view.dart';

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
  final MemoryService _memoryService = MemoryService();

  void _shiftTime(int step) {
    setState(() {
      if (_activeTabMode == 'Day') {
        _selectedDate = _selectedDate.add(Duration(days: step));
      } else if (_activeTabMode == 'Week') {
        _selectedDate = _selectedDate.add(Duration(days: step * 7));
      } else if (_activeTabMode == 'Month') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + step,
          _selectedDate.day,
        );
      } else {
        _selectedDate = DateTime(
          _selectedDate.year + step,
          _selectedDate.month,
          _selectedDate.day,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String dateStringKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final range = _activeRange();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Upper Mode Switch Tab Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Day', 'Week', 'Month', 'Year'].map((tabLabel) {
                final isSelected = _activeTabMode == tabLabel;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabMode = tabLabel),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD6A2A8)
                            : const Color(0xFFEDF6F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftTime(-1),
                  ),
                  Text(
                    _activeTabMode == 'Day'
                        ? DateFormat(
                            'EEEE, d, MMMM, yyyy',
                          ).format(_selectedDate)
                        : _activeTabMode == 'Week'
                        ? '${DateFormat('MMM d').format(range.$1)} - ${DateFormat('MMM d, yyyy').format(range.$2.subtract(const Duration(days: 1)))}'
                        : _activeTabMode == 'Month'
                        ? DateFormat('MMMM, yyyy').format(_selectedDate)
                        : DateFormat('yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftTime(1),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _activeTabMode == 'Day'
                ? _buildDayMemories(dateStringKey)
                : _buildCalendarGrid(range.$1, range.$2),
          ),
          _buildOnThisDayLastYear(),
        ],
      ),
    );
  }

  Widget _buildDayMemories(String dateStringKey) {
    return StreamBuilder<List<Memory>>(
      stream: _memoryService.streamDay(_uid, _selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyPlaceholder();
        }

        final memories = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: memories.length,
          itemBuilder: (ctx, i) {
            final memory = memories[i];
            final imageProvider = appImageProvider(memory.mediaUrl);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaInspectorView(memory: memory),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: memory.type == MemoryType.image && imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: memory.type == MemoryType.video
                    ? const Icon(Icons.play_circle_fill, color: Colors.black45, size: 48)
                    : imageProvider == null
                        ? const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black26,
                          )
                        : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarGrid(DateTime start, DateTime end) {
    return StreamBuilder<List<Memory>>(
      stream: _memoryService.streamRange(_uid, start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final memories = snapshot.data ?? [];
        final byDate = <String, List<Memory>>{};
        for (final memory in memories) {
          byDate.putIfAbsent(memory.dateKey, () => []).add(memory);
        }

        final days = end.difference(start).inDays;
        if (days <= 0) return _buildEmptyPlaceholder();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _activeTabMode == 'Year' ? 4 : 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: days,
          itemBuilder: (context, index) {
            final date = start.add(Duration(days: index));
            final key = MemoryService.dateKey(date);
            final dayMemories = byDate[key] ?? [];
            final first = dayMemories.isEmpty ? null : dayMemories.first;
            final imageProvider = first == null ? null : appImageProvider(first.mediaUrl);
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _activeTabMode = 'Day';
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6F4),
                  borderRadius: BorderRadius.circular(10),
                  image: first?.type == MemoryType.image && imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 6,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (dayMemories.length > 1)
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFFD6A2A8),
                          child: Text(
                            '${dayMemories.length}',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    if (first?.type == MemoryType.video)
                      const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.black45),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOnThisDayLastYear() {
    return StreamBuilder<List<Memory>>(
      stream: _memoryService.streamOnThisDayLastYear(_uid, _selectedDate),
      builder: (context, snapshot) {
        final memories = snapshot.data ?? [];
        if (memories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 116,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'On This Day Last Year',
                  style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: memories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MediaInspectorView(memory: memory)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 86,
                          child: memory.type == MemoryType.video
                              ? const ColoredBox(
                                  color: Color(0xFFEDF6F4),
                                  child: Icon(Icons.play_circle_fill),
                                )
                              : appImage(memory.mediaUrl),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (DateTime, DateTime) _activeRange() {
    if (_activeTabMode == 'Week') {
      final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      return (DateTime(start.year, start.month, start.day), DateTime(start.year, start.month, start.day + 7));
    }
    if (_activeTabMode == 'Month') {
      final start = DateTime(_selectedDate.year, _selectedDate.month);
      return (start, DateTime(_selectedDate.year, _selectedDate.month + 1));
    }
    if (_activeTabMode == 'Year') {
      final start = DateTime(_selectedDate.year);
      return (start, DateTime(_selectedDate.year + 1));
    }
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return (start, start.add(const Duration(days: 1)));
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          const Text(
            "No memories logged for this time scope.",
            style: TextStyle(color: Colors.black38, fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }
}
