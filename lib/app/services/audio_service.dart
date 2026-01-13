import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/video_model.dart';

enum PlayMode { video, audioOnly }

enum RepeatMode { off, one, all }

class AudioService extends GetxService {
  VideoPlayerController? videoController;
  AudioPlayer? _audioPlayer;
  final YoutubeExplode _yt = YoutubeExplode();
  AudioSession? _session;
  bool _isDisposed = false;
  bool _isSwitching = false;

  // Current state
  final currentVideo = Rxn<VideoModel>();
  final isLoading = false.obs;
  final isPlaying = false.obs;
  final isVideoReady = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final errorMessage = ''.obs;
  final playMode = PlayMode.video.obs;

  // Playlist
  final playlist = <VideoModel>[].obs;
  final currentIndex = 0.obs;
  final repeatMode = RepeatMode.off.obs;
  final shuffle = false.obs;

  // Auto download
  final autoDownload = true.obs;
  final downloadedIds = <String>{}.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  static const int maxDownloads = 100;

  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  @override
  void onInit() {
    super.onInit();
    _initAudioSession();
    _initAudioPlayerListeners();
    _loadDownloadedList();
  }

  Future<void> _loadDownloadedList() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (await downloadsDir.exists()) {
        final files = downloadsDir.listSync();
        for (var file in files) {
          final name = file.path.split('/').last;
          if (name.endsWith('.mp3')) {
            downloadedIds.add(name);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading downloaded list: $e');
    }
  }

  /// Enforce max downloads limit by deleting oldest files
  Future<void> _enforceMaxDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) return;

      final files = downloadsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp3'))
          .toList();

      if (files.length <= maxDownloads) return;

      // Sort by modified date (oldest first)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return aStat.modified.compareTo(bStat.modified);
      });

      // Delete oldest files until we're at maxDownloads
      final toDelete = files.length - maxDownloads;
      for (var i = 0; i < toDelete; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        await file.delete();
        downloadedIds.remove(fileName);
        debugPrint('Deleted old download: $fileName');
      }
    } catch (e) {
      debugPrint('Error enforcing max downloads: $e');
    }
  }

  Future<void> _initAudioSession() async {
    _session = await AudioSession.instance;
    await _session!.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _session!.interruptionEventStream.listen((event) {
      if (event.begin) pause();
    });

    _session!.becomingNoisyEventStream.listen((_) => pause());
  }

  void _initAudioPlayerListeners() {
    audioPlayer.durationStream.listen((d) {
      if (d != null && playMode.value == PlayMode.audioOnly) {
        totalDuration.value = d;
      }
    });

    audioPlayer.positionStream.listen((p) {
      if (playMode.value == PlayMode.audioOnly) {
        currentPosition.value = p;
      }
    });

    audioPlayer.playingStream.listen((playing) {
      if (playMode.value == PlayMode.audioOnly) {
        isPlaying.value = playing;
      }
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed &&
          playMode.value == PlayMode.audioOnly) {
        _onTrackComplete();
      }
    });
  }

  void setPlaylist(List<VideoModel> videos, {int startIndex = 0}) {
    playlist.assignAll(videos);
    currentIndex.value = startIndex;
    if (videos.isNotEmpty) {
      playVideo(videos[startIndex]);
    }
  }

  void addToPlaylist(VideoModel video) {
    if (!playlist.any((v) => v.id == video.id)) {
      playlist.add(video);
    }
  }

  Future<void> playNext() async {
    if (playlist.isEmpty || _isSwitching) return;

    int nextIndex;
    if (shuffle.value) {
      nextIndex = (currentIndex.value +
              1 +
              (playlist.length > 1
                  ? DateTime.now().millisecond % (playlist.length - 1)
                  : 0)) %
          playlist.length;
    } else {
      nextIndex = currentIndex.value + 1;
    }

    if (nextIndex >= playlist.length) {
      if (repeatMode.value == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }

    currentIndex.value = nextIndex;
    await playVideo(playlist[nextIndex]);
  }

  Future<void> playPrevious() async {
    if (playlist.isEmpty || _isSwitching) return;

    if (currentPosition.value.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }

    int prevIndex = currentIndex.value - 1;
    if (prevIndex < 0) {
      if (repeatMode.value == RepeatMode.all) {
        prevIndex = playlist.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    currentIndex.value = prevIndex;
    await playVideo(playlist[prevIndex]);
  }

  void toggleRepeat() {
    switch (repeatMode.value) {
      case RepeatMode.off:
        repeatMode.value = RepeatMode.all;
        break;
      case RepeatMode.all:
        repeatMode.value = RepeatMode.one;
        break;
      case RepeatMode.one:
        repeatMode.value = RepeatMode.off;
        break;
    }
  }

  void toggleShuffle() {
    shuffle.value = !shuffle.value;
  }

  void toggleAutoDownload() {
    autoDownload.value = !autoDownload.value;
  }

  Future<void> playVideo(VideoModel video,
      {PlayMode mode = PlayMode.audioOnly}) async {
    if (_isDisposed || _isSwitching) return;

    if (currentVideo.value?.id == video.id && playMode.value == mode) {
      if (mode == PlayMode.video && videoController != null) {
        videoController!.play();
        return;
      } else if (mode == PlayMode.audioOnly) {
        audioPlayer.play();
        return;
      }
    }

    _isSwitching = true;
    await _stopPlayers();

    isLoading.value = true;
    errorMessage.value = '';
    currentVideo.value = video;
    playMode.value = mode;

    final idx = playlist.indexWhere((v) => v.id == video.id);
    if (idx >= 0) currentIndex.value = idx;

    try {
      debugPrint('Getting manifest for: ${video.id}');
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);

      await _session?.setActive(true);

      if (mode == PlayMode.audioOnly) {
        await _playAudioOnly(video, manifest);
      } else {
        await _playVideo(video, manifest);
      }
    } catch (e) {
      debugPrint('Error: $e');
      errorMessage.value = 'Tidak dapat memutar';
      isVideoReady.value = false;
    } finally {
      isLoading.value = false;
      _isSwitching = false;
    }
  }

  Future<void> _playVideo(VideoModel video, StreamManifest manifest) async {
    if (manifest.muxed.isEmpty) {
      throw Exception('No playable stream found');
    }

    final stream = manifest.muxed.withHighestBitrate();
    final videoUrl = stream.url.toString();

    debugPrint('Playing video: ${video.title}');

    videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
      },
    );

    await videoController!.initialize();

    totalDuration.value = videoController!.value.duration;
    isVideoReady.value = true;

    videoController!.addListener(_videoListener);
    videoController!.play();
  }

  Future<void> _playAudioOnly(VideoModel video, StreamManifest manifest) async {
    if (manifest.muxed.isEmpty) {
      throw Exception('No stream found');
    }

    final muxed = manifest.muxed.withHighestBitrate();
    final audioUrl = muxed.url.toString();

    debugPrint('Playing audio: ${video.title}');

    try {
      await audioPlayer.setAudioSource(
        ProgressiveAudioSource(
          Uri.parse(audioUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
          },
          tag: MediaItem(
            id: video.id,
            title: video.title,
            artist: video.channelName,
            artUri: Uri.parse(video.thumbnail),
          ),
        ),
      );

      isVideoReady.value = true;
      await audioPlayer.play();
    } catch (e) {
      debugPrint('Audio error: $e');
      rethrow;
    }
  }

  void _videoListener() {
    if (videoController != null && playMode.value == PlayMode.video) {
      isPlaying.value = videoController!.value.isPlaying;
      currentPosition.value = videoController!.value.position;

      if (videoController!.value.position >= videoController!.value.duration &&
          videoController!.value.duration > Duration.zero &&
          !_isSwitching) {
        _onTrackComplete();
      }
    }
  }

  void _onTrackComplete() {
    if (_isSwitching) return;

    debugPrint('Track completed - auto download check');

    // Auto download audio if enabled
    if (autoDownload.value && currentVideo.value != null) {
      debugPrint('Starting auto download for: ${currentVideo.value!.title}');
      _autoDownloadAudio(currentVideo.value!);
    }

    if (repeatMode.value == RepeatMode.one) {
      seekTo(Duration.zero);
      play();
    } else if (playlist.length > 1) {
      playNext();
    } else if (repeatMode.value == RepeatMode.all && playlist.length == 1) {
      seekTo(Duration.zero);
      play();
    } else {
      seekTo(Duration.zero);
      pause();
    }
  }

  /// Manual download current track
  Future<void> downloadCurrentTrack() async {
    if (currentVideo.value != null) {
      await _autoDownloadAudio(currentVideo.value!);
    }
  }

  /// Auto download audio after track completes
  Future<void> _autoDownloadAudio(VideoModel video) async {
    final fileName = '${_sanitizeFileName(video.title)}.mp3';

    // Check if already downloaded
    if (downloadedIds.contains(fileName)) {
      debugPrint('Already downloaded: ${video.title}');
      return;
    }

    // Don't download if already downloading
    if (isDownloading.value) return;

    debugPrint('Auto downloading: ${video.title}');
    isDownloading.value = true;
    downloadProgress.value = 0;

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);

      // Get audio only stream
      AudioOnlyStreamInfo? audioStream;
      if (manifest.audioOnly.isNotEmpty) {
        final streams = manifest.audioOnly.toList();
        streams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        audioStream = streams.first;
      }

      if (audioStream == null) {
        debugPrint('No audio stream available');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');
      final fileStream = file.openWrite();

      final stream = _yt.videos.streamsClient.get(audioStream);
      final totalBytes = audioStream.size.totalBytes;
      var downloadedBytes = 0;

      await for (final data in stream) {
        fileStream.add(data);
        downloadedBytes += data.length;
        downloadProgress.value = (downloadedBytes / totalBytes) * 100;
      }

      await fileStream.close();

      downloadedIds.add(fileName);
      debugPrint('Downloaded: ${video.title}');

      // Enforce max downloads limit
      await _enforceMaxDownloads();

      Get.snackbar(
        'Auto Download',
        '${video.title} tersimpan (${downloadedIds.length}/$maxDownloads)',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Auto download error: $e');
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0;
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  /// Check if video is already downloaded
  bool isDownloaded(VideoModel video) {
    final fileName = '${_sanitizeFileName(video.title)}.mp3';
    return downloadedIds.contains(fileName);
  }

  void togglePlay() {
    if (playMode.value == PlayMode.audioOnly) {
      if (audioPlayer.playing) {
        audioPlayer.pause();
      } else {
        audioPlayer.play();
      }
    } else if (videoController != null) {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
    }
  }

  void play() {
    if (playMode.value == PlayMode.audioOnly) {
      audioPlayer.play();
    } else {
      videoController?.play();
    }
  }

  void pause() {
    if (playMode.value == PlayMode.audioOnly) {
      audioPlayer.pause();
    } else {
      videoController?.pause();
    }
  }

  void seekTo(Duration position) {
    if (playMode.value == PlayMode.audioOnly) {
      audioPlayer.seek(position);
    } else {
      videoController?.seekTo(position);
    }
  }

  void seekForward() {
    final newPos = currentPosition.value + const Duration(seconds: 10);
    if (newPos < totalDuration.value) {
      seekTo(newPos);
    }
  }

  void seekBackward() {
    final newPos = currentPosition.value - const Duration(seconds: 10);
    seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> switchToAudioMode() async {
    if (currentVideo.value == null || _isSwitching) return;
    if (playMode.value == PlayMode.audioOnly) return;

    final currentPos = currentPosition.value;
    final video = currentVideo.value!;

    await playVideo(video, mode: PlayMode.audioOnly);

    await Future.delayed(const Duration(milliseconds: 500));
    seekTo(currentPos);
  }

  Future<void> switchToVideoMode() async {
    if (currentVideo.value == null || _isSwitching) return;
    if (playMode.value == PlayMode.video) return;

    final currentPos = currentPosition.value;
    final video = currentVideo.value!;

    await playVideo(video, mode: PlayMode.video);

    await Future.delayed(const Duration(milliseconds: 500));
    seekTo(currentPos);
  }

  Future<void> _stopPlayers() async {
    videoController?.removeListener(_videoListener);
    await videoController?.pause();
    await videoController?.dispose();
    videoController = null;

    await audioPlayer.stop();

    isVideoReady.value = false;
    isPlaying.value = false;
    currentPosition.value = Duration.zero;
    totalDuration.value = Duration.zero;
  }

  Future<void> stop() async {
    _isSwitching = true;
    await _stopPlayers();
    await _session?.setActive(false);
    currentVideo.value = null;
    playlist.clear();
    currentIndex.value = 0;
    _isSwitching = false;
  }

  @override
  void onClose() {
    _isDisposed = true;
    videoController?.dispose();
    _audioPlayer?.dispose();
    _yt.close();
    super.onClose();
  }
}
