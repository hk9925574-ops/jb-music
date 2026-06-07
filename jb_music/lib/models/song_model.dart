class SongModel {
  final String id;
  final String title;
  final String path;
  final String? artist;

  SongModel({
    required this.id, 
    required this.title, 
    required this.path, 
    this.artist
  });

  // This helper helps the app convert your data into the right format
  factory SongModel.fromEntity(dynamic entity) {
    return SongModel(
      id: entity.id,
      title: entity.title,
      path: entity.path ?? '',
      artist: entity.artist,
    );
  }
}