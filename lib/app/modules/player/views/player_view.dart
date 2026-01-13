import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/player_controller.dart';
import '../../../services/audio_service.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  AudioService get audioService => controller.audioService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayer(),
            _buildModeIndicator(),
            _buildVideoInfo(),
            _buildPlayerControls(context),
            _buildPlaylistSection(),
            _buildDownloadSection(),
            const SizedBox(height: 100), // Space for mini player
          ],
        ),
      ),
    );
  }

  Widget _buildModeIndicator() {
    return Obx(() {
      final colorScheme = Get.theme.colorScheme;

      return Column(
        children: [
          // Mode selector tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            color: audioService.playMode.value ==
                                    PlayMode.audioOnly
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
                              color:
                                  audioService.playMode.value == PlayMode.video
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
          ),

          // Auto download indicator
          if (audioService.autoDownload.value)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.green.withAlpha(25),
              child: Row(
                children: [
                  const Icon(Icons.download_done,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Auto download aktif',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                  if (audioService.isDownloading.value)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: audioService.downloadProgress.value / 100,
                      ),
                    ),
                  TextButton(
                    onPressed: audioService.toggleAutoDownload,
                    child: const Text('OFF', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildVideoPlayer() {
    return Obx(() {
      if (audioService.isLoading.value) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: controller.video.thumbnail,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 220, color: Colors.black45),
            const CircularProgressIndicator(color: Colors.white),
          ],
        );
      }

      if (audioService.playMode.value == PlayMode.audioOnly) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: controller.video.thumbnail,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 220, color: Colors.black45),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => IconButton(
                      iconSize: 72,
                      icon: Icon(
                        audioService.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: audioService.togglePlay,
                    )),
                const Text('Audio Mode',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        );
      }

      if (audioService.errorMessage.isNotEmpty ||
          !audioService.isVideoReady.value) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: controller.video.thumbnail,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(height: 220, color: Colors.black54),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  audioService.errorMessage.value.isNotEmpty
                      ? audioService.errorMessage.value
                      : 'Video tidak tersedia',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: audioService.switchToAudioMode,
                      icon: const Icon(Icons.headphones),
                      label: const Text('Audio Only'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: controller.openInYouTube,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('YouTube'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      final videoController = audioService.videoController;
      if (videoController == null) {
        return const SizedBox(height: 220);
      }

      return AspectRatio(
        aspectRatio: videoController.value.aspectRatio.clamp(0.5, 2.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(videoController),
            Positioned.fill(
              child: GestureDetector(
                onTap: audioService.togglePlay,
                child: Obx(() => AnimatedOpacity(
                      opacity: !audioService.isPlaying.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill,
                              size: 72, color: Colors.white),
                        ),
                      ),
                    )),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.video.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            controller.video.channelName,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return Obx(() {
      if (!audioService.isVideoReady.value) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Obx(() => Slider(
                    value:
                        audioService.currentPosition.value.inSeconds.toDouble(),
                    max: audioService.totalDuration.value.inSeconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    onChanged: (value) {
                      audioService.seekTo(Duration(seconds: value.toInt()));
                    },
                  )),
            ),
            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(audioService.currentPosition.value)),
                      Text(_formatDuration(audioService.totalDuration.value)),
                    ],
                  )),
            ),
            const SizedBox(height: 8),
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shuffle
                Obx(() => IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        size: 20,
                        color: audioService.shuffle.value
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: audioService.toggleShuffle,
                    )),
                // Previous
                IconButton(
                  iconSize: 32,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: audioService.playPrevious,
                ),
                // Rewind
                IconButton(
                  iconSize: 28,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.replay_10),
                  onPressed: audioService.seekBackward,
                ),
                // Play/Pause
                Obx(() => IconButton(
                      iconSize: 56,
                      icon: Icon(
                        audioService.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: audioService.togglePlay,
                    )),
                // Forward
                IconButton(
                  iconSize: 28,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.forward_10),
                  onPressed: audioService.seekForward,
                ),
                // Next
                IconButton(
                  iconSize: 32,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.skip_next),
                  onPressed: audioService.playNext,
                ),
                // Repeat
                Obx(() {
                  IconData icon;
                  Color color;
                  switch (audioService.repeatMode.value) {
                    case RepeatMode.off:
                      icon = Icons.repeat;
                      color = Colors.grey;
                      break;
                    case RepeatMode.all:
                      icon = Icons.repeat;
                      color = Theme.of(context).colorScheme.primary;
                      break;
                    case RepeatMode.one:
                      icon = Icons.repeat_one;
                      color = Theme.of(context).colorScheme.primary;
                      break;
                  }
                  return IconButton(
                    icon: Icon(icon, size: 20, color: color),
                    visualDensity: VisualDensity.compact,
                    onPressed: audioService.toggleRepeat,
                  );
                }),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlaylistSection() {
    return Obx(() {
      if (audioService.playlist.length <= 1) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Row(
              children: [
                const Text(
                  'Playlist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${audioService.currentIndex.value + 1} / ${audioService.playlist.length}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
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
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isPlaying
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: video.thumbnail,
                              width: 120,
                              height: 80,
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
                                    color: Colors.white),
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
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildDownloadSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Download',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.availableQualities.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Column(
              children: controller.availableQualities
                  .map((quality) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            quality['isAudio'] == true
                                ? Icons.audiotrack
                                : Icons.video_file,
                          ),
                          title: Text(quality['label'] ?? ''),
                          subtitle: Text(quality['size'] ?? ''),
                          trailing: Obx(() {
                            if (controller.downloadingQuality.value ==
                                quality['tag']) {
                              return SizedBox(
                                width: 48,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      value: controller.downloadProgress.value /
                                          100,
                                      strokeWidth: 3,
                                    ),
                                    Text(
                                        '${controller.downloadProgress.value.toInt()}%',
                                        style: const TextStyle(fontSize: 10)),
                                  ],
                                ),
                              );
                            }
                            return FilledButton.icon(
                              onPressed: () =>
                                  controller.downloadVideo(quality['tag']),
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Download'),
                            );
                          }),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
