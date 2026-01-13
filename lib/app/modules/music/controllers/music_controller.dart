import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../data/models/video_model.dart';
import '../../../services/audio_service.dart';
import '../../../widgets/player_bottom_sheet.dart';

class MusicController extends GetxController {
  final searchController = TextEditingController();
  final yt = YoutubeExplode();

  final isLoading = false.obs;
  final musicVideos = <VideoModel>[].obs;
  final searchResults = <VideoModel>[].obs;
  final searchQuery = ''.obs;
  final selectedCategory = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMusic();
  }

  @override
  void onClose() {
    searchController.dispose();
    yt.close();
    super.onClose();
  }

  Future<void> loadMusic() async {
    isLoading.value = true;
    try {
      final query = selectedCategory.isEmpty
          ? 'music video trending 2024'
          : '${selectedCategory.value} music 2024';

      final searchList = await yt.search.search(query);
      musicVideos.clear();

      for (var video in searchList.take(20)) {
        musicVideos.add(VideoModel(
          id: video.id.value,
          title: video.title,
          thumbnail: video.thumbnails.highResUrl,
          channelName: video.author,
          duration: _formatDuration(video.duration),
        ));
      }
    } catch (e) {
      debugPrint('Error loading music: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchMusic(String query) async {
    if (query.trim().isEmpty) return;

    isLoading.value = true;
    searchResults.clear();

    try {
      final searchList = await yt.search.search('$query music');

      for (var video in searchList.take(20)) {
        searchResults.add(VideoModel(
          id: video.id.value,
          title: video.title,
          thumbnail: video.thumbnails.highResUrl,
          channelName: video.author,
          duration: _formatDuration(video.duration),
        ));
      }
    } catch (e) {
      debugPrint('Error searching music: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = '';
    } else {
      selectedCategory.value = category;
    }
    searchResults.clear();
    loadMusic();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
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
    // Set playlist from current music list
    final audioService = Get.find<AudioService>();
    final allVideos = searchResults.isNotEmpty ? searchResults : musicVideos;
    final index = allVideos.indexWhere((v) => v.id == video.id);
    audioService.setPlaylist(allVideos.toList(),
        startIndex: index >= 0 ? index : 0);

    Get.bottomSheet(
      const PlayerBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
