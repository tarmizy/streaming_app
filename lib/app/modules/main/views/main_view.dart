import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../home/views/home_view.dart';
import '../../music/views/music_view.dart';
import '../../news/views/news_view.dart';
import '../../../widgets/mini_player.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  static const Color primaryColor = Color(0xFF6B5CE7);
  static const Color accentColor = Color(0xFFE966A0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Obx(() => IndexedStack(
                  index: controller.currentIndex.value,
                  children: const [
                    HomeView(),
                    MusicView(),
                    NewsView(),
                  ],
                )),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: Obx(() => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, accentColor],
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.white.withAlpha(50),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                    }
                    return const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    );
                  }),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.white.withAlpha(50),
                selectedIndex: controller.currentIndex.value,
                onDestinationSelected: controller.changePage,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined,
                        color: Colors.white, size: 26),
                    selectedIcon:
                        Icon(Icons.home, color: Colors.white, size: 28),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.music_note_outlined,
                        color: Colors.white, size: 26),
                    selectedIcon:
                        Icon(Icons.music_note, color: Colors.white, size: 28),
                    label: 'Music',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.newspaper_outlined,
                        color: Colors.white, size: 26),
                    selectedIcon:
                        Icon(Icons.newspaper, color: Colors.white, size: 28),
                    label: 'News',
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
