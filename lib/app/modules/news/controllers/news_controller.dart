import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../data/models/video_model.dart';
import '../../../services/audio_service.dart';
import '../../../widgets/player_bottom_sheet.dart';

class NewsController extends GetxController {
  final yt = YoutubeExplode();

  final isLoading = false.obs;
  final newsVideos = <VideoModel>[].obs;
  final breakingNews = <VideoModel>[].obs;
  final selectedCategory = 'Semua'.obs;

  @override
  void onInit() {
    super.onInit();
    loadNews();
  }

  @override
  void onClose() {
    yt.close();
    super.onClose();
  }

  Future<void> loadNews() async {
    isLoading.value = true;
    try {
      String query;
      switch (selectedCategory.value) {
        case 'Indonesia':
          query = 'berita indonesia terbaru hari ini';
          break;
        case 'Dunia':
          query = 'berita dunia internasional terbaru';
          break;
        case 'Teknologi':
          query = 'berita teknologi terbaru';
          break;
        case 'Olahraga':
          query = 'berita olahraga terbaru';
          break;
        case 'Bisnis':
          query = 'berita bisnis ekonomi terbaru';
          break;
        default:
          query = 'berita terbaru hari ini indonesia';
      }

      final searchList = await yt.search.search(query);
      newsVideos.clear();
      breakingNews.clear();

      var count = 0;
      for (var video in searchList.take(20)) {
        final videoModel = VideoModel(
          id: video.id.value,
          title: video.title,
          thumbnail: video.thumbnails.highResUrl,
          channelName: video.author,
          duration: _formatDuration(video.duration),
        );

        if (count == 0) {
          breakingNews.add(videoModel);
        } else {
          newsVideos.add(videoModel);
        }
        count++;
      }
    } catch (e) {
      debugPrint('Error loading news: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    loadNews();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }

  void openVideo(VideoModel video) {
    // Set playlist from news list
    final audioService = Get.find<AudioService>();
    final allVideos = [...breakingNews, ...newsVideos];
    final index = allVideos.indexWhere((v) => v.id == video.id);
    audioService.setPlaylist(allVideos, startIndex: index >= 0 ? index : 0);

    Get.bottomSheet(
      const PlayerBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
