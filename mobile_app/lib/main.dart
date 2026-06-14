import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/playback_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'widgets/player_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicyApp());
}

class MusicyApp extends StatelessWidget {
  const MusicyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
      ],
      child: MaterialApp(
        title: 'Musicy - Spotify Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: const Color(0xFF1DB954),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1DB954),
            secondary: Color(0xFF1DB954),
            surface: Color(0xFF121212),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0C0C0C),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 10),
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const MainLayout(),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating Bottom Mini Player
          const PlayerBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Your Library',
          ),
        ],
      ),
    );
  }
}
