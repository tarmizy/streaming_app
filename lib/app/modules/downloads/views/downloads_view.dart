import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controllers/downloads_controller.dart';

class DownloadsView extends GetView<DownloadsController> {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadDownloads,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.downloadedFiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_done, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Belum ada video yang didownload'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.downloadedFiles.length,
          itemBuilder: (context, index) {
            final file = controller.downloadedFiles[index];
            return _buildFileCard(file);
          },
        );
      }),
    );
  }

  Widget _buildFileCard(FileSystemEntity file) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => controller.shareFile(file),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(file),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Hapus',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.video_file, size: 32),
          ),
          title: Text(
            controller.getFileName(file),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(controller.getFileSize(file)),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_fill, size: 40),
            color: Colors.red,
            onPressed: () => controller.playVideo(file),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(FileSystemEntity file) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Video'),
        content: const Text('Yakin ingin menghapus video ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteFile(file);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
