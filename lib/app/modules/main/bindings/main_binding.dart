import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../music/controllers/music_controller.dart';
import '../../news/controllers/news_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MusicController>(() => MusicController());
    Get.lazyPut<NewsController>(() => NewsController());
  }
}
