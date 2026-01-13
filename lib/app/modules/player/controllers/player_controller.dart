import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/video_model.dart';
import '../../../services/audio_service.dart';

class PlayerController extends GetxController {
  late VideoModel video;
  final yt = YoutubeExplode();
  final audioService = Get.find<AudioService>();

  final availableQualities = <Map<String, dynamic>>[].obs;
  final downloadProgress = 0.0.obs;
  final downloadingQuality = ''.obs;

  @override
  void onInit() {
    super.onInit();
    video = Get.arguments as VideoModel;

    // Play video using global audio service
    audioService.playVideo(video);
    _loadQualities();
  }

  Future<void> openInYouTube() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${video.id}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadQualities() async {
    try {
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final muxedStreams = manifest.muxed.toList();

      muxedStreams
          .sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));

      for (var stream in muxedStreams) {
        availableQualities.add({
          'tag': stream.tag.toString(),
          'label': stream.videoQualityLabel,
          'size': _formatBytes(stream.size.totalBytes),
          'stream': stream,
        });
      }

      // Add audio only option
      final audioStreams = manifest.audioOnly.toList();
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      if (audioStreams.isNotEmpty) {
        final best = audioStreams.first;
        availableQualities.add({
          'tag': 'audio_${best.tag}',
          'label':
              'Audio Only (${best.bitrate.kiloBitsPerSecond.toStringAsFixed(0)} kbps)',
          'size': _formatBytes(best.size.totalBytes),
          'stream': best,
          'isAudio': true,
        });
      }
    } catch (e) {
      debugPrint('Error loading qualities: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> downloadVideo(String? tag) async {
    if (tag == null) return;

    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    downloadingQuality.value = tag;
    downloadProgress.value = 0;

    try {
      final quality = availableQualities.firstWhere((q) => q['tag'] == tag);
      final isAudio = quality['isAudio'] == true;

      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final ext = isAudio ? 'mp3' : 'mp4';
      final fileName =
          '${video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.$ext';
      final file = File('${downloadsDir.path}/$fileName');
      final fileStream = file.openWrite();

      final stream = quality['stream'];
      final videoStream = yt.videos.streamsClient.get(stream);
      final totalBytes = stream.size.totalBytes;
      var downloadedBytes = 0;

      await for (final data in videoStream) {
        fileStream.add(data);
        downloadedBytes += data.length;
        downloadProgress.value = (downloadedBytes / totalBytes) * 100;
      }

      await fileStream.close();

      Get.snackbar(
        'Berhasil',
        'File berhasil didownload',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal mendownload: $e');
    } finally {
      downloadingQuality.value = '';
      downloadProgress.value = 0;
    }
  }

  @override
  void onClose() {
    yt.close();
    // Don't stop audio service here - let it continue playing
    super.onClose();
  }
}
