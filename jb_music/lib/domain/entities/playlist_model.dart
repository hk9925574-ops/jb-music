// lib/domain/entities/playlist_model.dart
import 'package:equatable/equatable.dart';

class PlaylistModel extends Equatable {
  final String id;
  final String name;
  final List<String> trackIds;
  final DateTime createdAt;
  final String? description;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.trackIds,
    required this.createdAt,
    this.description,
  });

  // ── Factory ───────────────────────────────────────────────────────────────
  factory PlaylistModel.create({
    required String name,
    String? description,
  }) {
    return PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      trackIds: const [],
      createdAt: DateTime.now(),
      description: description,
    );
  }

  // ── JSON ──────────────────────────────────────────────────────────────────
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      trackIds: List<String>.from(json['trackIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trackIds': trackIds,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
      };

  // ── CopyWith ──────────────────────────────────────────────────────────────
  PlaylistModel copyWith({
    String? id,
    String? name,
    List<String>? trackIds,
    DateTime? createdAt,
    String? description,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int get trackCount => trackIds.length;
  bool get isEmpty => trackIds.isEmpty;
  bool containsTrack(String trackId) => trackIds.contains(trackId);

  @override
  List<Object?> get props => [id, name, trackIds, createdAt, description];

  @override
  String toString() =>
      'PlaylistModel(id: $id, name: "$name", tracks: $trackCount)';
}