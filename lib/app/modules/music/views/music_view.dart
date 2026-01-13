import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/music_controller.dart';

class MusicView extends GetView<MusicController> {
  const MusicView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            toolbarHeight: 56,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B5CE7), Color(0xFFE966A0)],
                ),
              ),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('Music',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearchBar(context),
          ),
          SliverToBoxAdapter(
            child: _buildCategories(context),
          ),
          SliverToBoxAdapter(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SearchBar(
        controller: controller.searchController,
        hintText: 'Cari musik, artis, album...',
        elevation: const WidgetStatePropertyAll(1),
        backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        leading: Icon(Icons.search_rounded, color: colorScheme.primary),
        trailing: [
          Obx(() {
            if (controller.isLoading.value) {
              return const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (controller.searchQuery.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        onSubmitted: controller.searchMusic,
        onChanged: (value) => controller.searchQuery.value = value,
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = [
      'Pop',
      'Rock',
      'Jazz',
      'Dangdut',
      'K-Pop',
      'EDM',
      'Lo-Fi'
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Obx(() {
              final isSelected =
                  controller.selectedCategory.value == categories[index];
              return FilterChip(
                label: Text(categories[index]),
                selected: isSelected,
                onSelected: (_) => controller.selectCategory(categories[index]),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.searchResults.isNotEmpty) {
        return _buildSearchResults(context);
      }
      return _buildMusicList(context);
    });
  }

  Widget _buildSearchResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil Pencarian',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${controller.searchResults.length} musik',
                      style:
                          TextStyle(fontSize: 11, color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: controller.clearSearch,
                child: const Text('Hapus'),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final video = controller.searchResults[index];
            return _buildMusicCard(video, context);
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMusicList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.library_music_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => Text(
                    controller.selectedCategory.isEmpty
                        ? 'Trending Music'
                        : controller.selectedCategory.value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )),
              const Spacer(),
              Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
        Obx(() {
          if (controller.musicVideos.isEmpty && !controller.isLoading.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.music_off, size: 48, color: colorScheme.outline),
                    const SizedBox(height: 8),
                    Text('Tidak ada musik',
                        style: TextStyle(color: colorScheme.outline)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.musicVideos.length,
            itemBuilder: (context, index) {
              final video = controller.musicVideos[index];
              return _buildMusicCard(video, context);
            },
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMusicCard(video, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.openVideo(video),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.duration,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: colorScheme.outline, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.play_circle_fill_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
              onPressed: () => controller.openVideo(video),
            ),
          ],
        ),
      ),
    );
  }
}
