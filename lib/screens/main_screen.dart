import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_provider.dart';
import '../widgets/mini_audio_player_widget.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const LibraryScreen(),
      const SearchScreen(),
      const StatisticsScreen(),
      ProfileScreen(
        onSelectShelfFilter: (status) {
          ref.read(bookFilterProvider.notifier).state = status;
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: screens[_currentIndex]),
          const MiniAudioPlayerWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
