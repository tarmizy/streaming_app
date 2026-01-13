import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../data/models/video_model.dart';
import '../../../routes/app_pages.dart';
import '../../../services/audio_service.dart';
import '../../../widgets/player_bottom_sheet.dart';

class HomeController extends GetxController {
  final searchController = TextEditingController();
  final yt = YoutubeExplode();

  final isLoading = false.obs;
  final isLoadingTrending = false.obs;
  final searchResults = <VideoModel>[].obs;
  final trendingVideos = <VideoModel>[].obs;
  final recommendedVideos = <VideoModel>[].obs;
  final searchQuery = ''.obs;
  final errorMessage = ''.obs;

  // Recent searches
  final recentSearches = <String>[].obs;
  static const int maxRecentSearches = 5;

  // Downloaded count from AudioService
  int get downloadedCount {
    try {
      final audioService = Get.find<AudioService>();
      return audioService.downloadedIds.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadTrending();
    loadRecommended();
  }

  @override
  void onClose() {
    searchController.dispose();
    yt.close();
    super.onClose();
  }

  Future<void> loadTrending() async {
    isLoadingTrending.value = true;
    try {
      // Search for trending/popular videos
      final searchList = await yt.search.search('trending indonesia 2026');
      trendingVideos.clear();

      for (var video in searchList.take(10)) {
        trendingVideos.add(VideoModel(
          id: video.id.value,
          title: video.title,
          thumbnail: video.thumbnails.highResUrl,
          channelName: video.author,
          duration: _formatDuration(video.duration),
        ));
      }
    } catch (e) {
      debugPrint('Error loading trending: $e');
    } finally {
      isLoadingTrending.value = false;
    }
  }

  Future<void> loadRecommended() async {
    try {
      final searchList = await yt.search.search('popular music 2026');
      recommendedVideos.clear();

      for (var video in searchList.take(15)) {
        recommendedVideos.add(VideoModel(
          id: video.id.value,
          title: video.title,
          thumbnail: video.thumbnails.highResUrl,
          channelName: video.author,
          duration: _formatDuration(video.duration),
        ));
      }
    } catch (e) {
      debugPrint('Error loading recommended: $e');
    }
  }

  Future<void> searchVideos(String query) async {
    if (query.trim().isEmpty) return;

    // Add to recent searches
    _addToRecentSearches(query);

    isLoading.value = true;
    errorMessage.value = '';
    searchResults.clear();
    searchQuery.value = query;
    searchController.text = query;

    try {
      final searchList = await yt.search.search(query);

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
      errorMessage.value = 'Gagal mencari video: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _addToRecentSearches(String query) {
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > maxRecentSearches) {
      recentSearches.removeLast();
    }
  }

  void removeRecentSearch(String query) {
    recentSearches.remove(query);
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
    // Set playlist from current list
    final audioService = Get.find<AudioService>();
    final allVideos = searchResults.isNotEmpty
        ? searchResults
        : [...trendingVideos, ...recommendedVideos];
    final index = allVideos.indexWhere((v) => v.id == video.id);
    audioService.setPlaylist(allVideos, startIndex: index >= 0 ? index : 0);

    // Open player as bottom sheet modal
    Get.bottomSheet(
      const PlayerBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  void goToDownloads() {
    Get.toNamed(Routes.downloads);
  }
}
