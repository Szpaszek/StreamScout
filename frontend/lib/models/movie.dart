class Movie {
  final int id;
  final String title;
  final String overview;
  final String releaseDate;
  final String? posterPath; // Nullable to handle missing posters
  final double rating;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.releaseDate,
    this.posterPath,
    required this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No Title',
      overview: json['overview'] as String? ?? 'No Overview',
      releaseDate: json['release_date'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }

}