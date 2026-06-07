class PlaylistModel {
  final String name;
  final List<String> trackIds;

  PlaylistModel({required this.name, required this.trackIds});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'trackIds': trackIds,
    };
  }
}