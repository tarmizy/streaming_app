import 'package:get/get.dart';
import '../modules/main/bindings/main_binding.dart';
import '../modules/main/views/main_view.dart';
import '../modules/player/bindings/player_binding.dart';
import '../modules/player/views/player_view.dart';
import '../modules/downloads/bindings/downloads_binding.dart';
import '../modules/downloads/views/downloads_view.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.main;

  static final routes = [
    GetPage(
      name: Routes.main,
      page: () => const MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.player,
      page: () => const PlayerView(),
      binding: PlayerBinding(),
    ),
    GetPage(
      name: Routes.downloads,
      page: () => const DownloadsView(),
      binding: DownloadsBinding(),
    ),
  ];
}
