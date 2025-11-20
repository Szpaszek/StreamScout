import 'package:frontend/models/media.dart';

class Actor {
  final int id;
  final String name;
  final String? profilePath;
  final List<Media> knownFor;

  Actor ({
    required this.id,
    required this.name,
    this.profilePath,
    required this.knownFor,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {

    // deserialize the list of 'known_for' items using the Media.fromJson factory
    final knownForList = (json['known_for'] as List<dynamic>?)
      // each item is parsed as a full media object
      ?.map((item) => Media.fromJson(item as Map<String, dynamic>)).toList() ?? [];

    return Actor(
      id: json['id'] as int? ?? 0, 
      name: json['name'] as String? ?? 'Unknown Actor', 
      profilePath: json['profile_path'] as String?,
      knownFor: knownForList,
      );
  }
}
