class VideoModel {
  final String id;
  final String title;
  final String thumbnail;
  final String channelName;
  final String duration;
  final String? localPath;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.channelName,
    required this.duration,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
    'channelName': channelName,
    'duration': duration,
    'localPath': localPath,
  };

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
    id: json['id'],
    title: json['title'],
    thumbnail: json['thumbnail'],
    channelName: json['channelName'],
    duration: json['duration'],
    localPath: json['localPath'],
  );
}
