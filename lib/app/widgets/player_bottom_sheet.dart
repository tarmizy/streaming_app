import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_service.dart';

class PlayerBottomSheet extends StatelessWidget {
  const PlayerBottomSheet({super.key});

  AudioService get audioService => Get.find<AudioService>();

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar and header
              _buildHeader(context),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideoPlayer(context),
                      _buildModeSelector(context),
                      _buildVideoInfo(context),
                      _buildPlayerControls(context),
                      _buildPlaylistSection(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5CE7), Color(0xFFE966A0)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                const Expanded(
                  child: Text(
                    'Now Playing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    return Obx(() {
      final video = audioService.currentVideo.value;
      if (video == null) return const SizedBox(height: 200);

      // Audio mode - just show thumbnail (no loading indicator)
      if (audioService.playMode.value == PlayMode.audioOnly) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: video.thumbnail,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 200, color: Colors.black54),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => IconButton(
                      iconSize: 64,
                      icon: Icon(
                        audioService.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: audioService.togglePlay,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headphones, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Audio Mode',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }

      // Video mode - show loading
      if (audioService.isLoading.value) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: video.thumbnail,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 200, color: Colors.black45),
            const CircularProgressIndicator(color: Colors.white),
          ],
        );
      }

      // Video mode
      final videoController = audioService.videoController;
      if (videoController == null || !audioService.isVideoReady.value) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: video.thumbnail,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 200, color: Colors.black45),
            const CircularProgressIndicator(color: Colors.white),
          ],
        );
      }

      return AspectRatio(
        aspectRatio: videoController.value.aspectRatio.clamp(0.5, 2.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(videoController),
            GestureDetector(
              onTap: audioService.togglePlay,
              child: Obx(() => AnimatedOpacity(
                    opacity: !audioService.isPlaying.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.play_circle_fill,
                            size: 64, color: Colors.white),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (audioService.playMode.value != PlayMode.audioOnly) {
                      audioService.switchToAudioMode();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: audioService.playMode.value == PlayMode.audioOnly
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 18,
                          color:
                              audioService.playMode.value == PlayMode.audioOnly
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Audio',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: audioService.playMode.value ==
                                    PlayMode.audioOnly
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (audioService.playMode.value != PlayMode.video) {
                      audioService.switchToVideoMode();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: audioService.playMode.value == PlayMode.video
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 18,
                          color: audioService.playMode.value == PlayMode.video
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Video',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: audioService.playMode.value == PlayMode.video
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildVideoInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final video = audioService.currentVideo.value;
      if (video == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    video.channelName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                // Download button
                Obx(() {
                  if (audioService.isDownloading.value) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: audioService.downloadProgress.value / 100,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${audioService.downloadProgress.value.toInt()}%',
                          style: TextStyle(
                              fontSize: 11, color: colorScheme.primary),
                        ),
                      ],
                    );
                  }

                  final fileName = '${_sanitizeFileName(video.title)}.mp3';
                  final isDownloaded =
                      audioService.downloadedIds.contains(fileName);

                  return IconButton(
                    icon: Icon(
                      isDownloaded
                          ? Icons.download_done
                          : Icons.download_rounded,
                      color: isDownloaded ? Colors.green : colorScheme.primary,
                    ),
                    onPressed:
                        isDownloaded ? null : audioService.downloadCurrentTrack,
                    tooltip:
                        isDownloaded ? 'Sudah didownload' : 'Download audio',
                  );
                }),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlayerControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (!audioService.isVideoReady.value && !audioService.isLoading.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: audioService.currentPosition.value.inSeconds.toDouble(),
                max: audioService.totalDuration.value.inSeconds
                    .toDouble()
                    .clamp(1, double.infinity),
                onChanged: (value) {
                  audioService.seekTo(Duration(seconds: value.toInt()));
                },
              ),
            ),
            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(audioService.currentPosition.value),
                      style: const TextStyle(fontSize: 12)),
                  Text(_formatDuration(audioService.totalDuration.value),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shuffle
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    size: 20,
                    color: audioService.shuffle.value
                        ? colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: audioService.toggleShuffle,
                ),
                // Previous
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: audioService.playPrevious,
                ),
                // Rewind
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: audioService.seekBackward,
                ),
                // Play/Pause
                IconButton(
                  iconSize: 56,
                  icon: Icon(
                    audioService.isPlaying.value
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: colorScheme.primary,
                  ),
                  onPressed: audioService.togglePlay,
                ),
                // Forward
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: audioService.seekForward,
                ),
                // Next
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next),
                  onPressed: audioService.playNext,
                ),
                // Repeat
                IconButton(
                  icon: Icon(
                    audioService.repeatMode.value == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    size: 20,
                    color: audioService.repeatMode.value != RepeatMode.off
                        ? colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: audioService.toggleRepeat,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlaylistSection(BuildContext context) {
    return Obx(() {
      if (audioService.playlist.length <= 1) return const SizedBox.shrink();

      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Up Next',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${audioService.currentIndex.value + 1}/${audioService.playlist.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: audioService.playlist.length,
                itemBuilder: (context, index) {
                  final video = audioService.playlist[index];
                  final isPlaying = index == audioService.currentIndex.value;

                  return GestureDetector(
                    onTap: () {
                      audioService.currentIndex.value = index;
                      audioService.playVideo(video);
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isPlaying
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: video.thumbnail,
                              width: 100,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isPlaying)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
