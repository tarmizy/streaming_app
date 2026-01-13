import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DownloadsController extends GetxController {
  final downloadedFiles = <FileSystemEntity>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloads();
  }

  Future<void> loadDownloads() async {
    isLoading.value = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');

      if (await downloadsDir.exists()) {
        final files = downloadsDir
            .listSync()
            .where((f) => f.path.endsWith('.mp4'))
            .toList();
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        downloadedFiles.assignAll(files);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat downloads');
    } finally {
      isLoading.value = false;
    }
  }

  String getFileName(FileSystemEntity file) {
    return file.path.split('/').last.replaceAll('.mp4', '');
  }

  String getFileSize(FileSystemEntity file) {
    final bytes = File(file.path).lengthSync();
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> deleteFile(FileSystemEntity file) async {
    try {
      await File(file.path).delete();
      downloadedFiles.remove(file);
      Get.snackbar('Berhasil', 'File dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus file');
    }
  }

  Future<void> shareFile(FileSystemEntity file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> playVideo(FileSystemEntity file) async {
    // Open with system player
    Get.snackbar('Info', 'Membuka video...');
  }
}
