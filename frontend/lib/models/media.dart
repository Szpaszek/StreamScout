class Media {
  final int id;
  // this is needed to distinguish movie from tv 
  final String mediaType;
  // unified field: holds movie 'title' or TV show 'name'
  final String title;
  final String overview;
  // unified field: holds movie 'release_Date' or TV show 'first_air_date'
  final String releaseDate;
  final String? posterPath; // Nullable to handle missing posters
  final String? backdropPath; 
  final List<int> genreIds; 
  final double rating;

  Media({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.overview,
    required this.releaseDate,
    this.posterPath,
    this.backdropPath,
    required this.genreIds,
    required this.rating,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int? ?? 0,
      mediaType: json['media_Type'] as String? ?? 'movie',
      title: json['title'] as String? ?? 'No Title',
      overview: json['overview'] as String? ?? 'No Overview',
      releaseDate: json['release_date'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_Path'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

}