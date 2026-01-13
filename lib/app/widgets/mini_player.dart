import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_service.dart';
import 'player_bottom_sheet.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = Get.find<AudioService>();

    return Obx(() {
      final video = audioService.currentVideo.value;
      if (video == null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => Get.bottomSheet(
          const PlayerBottomSheet(),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Obx(() {
                final progress = audioService.totalDuration.value.inSeconds > 0
                    ? audioService.currentPosition.value.inSeconds /
                        audioService.totalDuration.value.inSeconds
                    : 0.0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: Colors.grey[300],
                    ),
                    if (audioService.isDownloading.value)
                      LinearProgressIndicator(
                        value: audioService.downloadProgress.value / 100,
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: Colors.green,
                      ),
                  ],
                );
              }),
              Expanded(
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                          Text(
                            video.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    Obx(() => audioService.playlist.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.skip_previous, size: 22),
                            visualDensity: VisualDensity.compact,
                            onPressed: audioService.playPrevious,
                          )
                        : const SizedBox.shrink()),
                    Obx(() {
                      if (audioService.isLoading.value) {
                        return const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        icon: Icon(
                          audioService.isPlaying.value
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 26,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: audioService.togglePlay,
                      );
                    }),
                    Obx(() => audioService.playlist.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.skip_next, size: 22),
                            visualDensity: VisualDensity.compact,
                            onPressed: audioService.playNext,
                          )
                        : const SizedBox.shrink()),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: audioService.stop,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
