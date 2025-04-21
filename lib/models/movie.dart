class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<String>? genres;
  final int? runtime;
  final String? director;
  final List<String>? cast;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.genres,
    this.runtime,
    this.director,
    this.cast,
  });

  // Factory constructor to create Movie object from JSON
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'],
    );
  }

  // Factory constructor to create Movie object from AI JSON
  factory Movie.fromAIJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      voteAverage: 0.0,
      voteCount: 0,
    );
  }

  // Factory constructor for detailed movie info
  factory Movie.fromDetailJson(Map<String, dynamic> json) {
    // Extract director from credits
    String? director;
    if (json['credits'] != null && json['credits']['crew'] != null) {
      final directors = (json['credits']['crew'] as List)
          .where((crew) => crew['job'] == 'Director')
          .toList();
      if (directors.isNotEmpty) {
        director = directors.first['name'];
      }
    }

    // Extract cast
    List<String> cast = [];
    if (json['credits'] != null && json['credits']['cast'] != null) {
      cast = (json['credits']['cast'] as List)
          .take(5)
          .map((actor) => actor['name'] as String)
          .toList();
    }

    // Extract genres
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List)
          .map((genre) => genre['name'] as String)
          .toList();
    }

    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'],
      genres: genres,
      runtime: json['runtime'],
      director: director,
      cast: cast,
    );
  }

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'releaseDate': releaseDate,
    };
  }

  // Create Movie object from Map (from Firestore)
  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      overview: map['overview'] ?? '',
      posterPath: map['posterPath'],
      backdropPath: map['backdropPath'],
      voteAverage: map['voteAverage'] ?? 0.0,
      voteCount: map['voteCount'] ?? 0,
      releaseDate: map['releaseDate'],
    );
  }

  // Get poster URL
  String get posterUrl {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return 'https://via.placeholder.com/500x750?text=No+Poster';
  }

  // Get backdrop URL
  String get backdropUrl {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w780$backdropPath';
    }
    return 'https://via.placeholder.com/780x439?text=No+Backdrop';
  }

  // Get release year
  String get releaseYear {
    if (releaseDate != null && releaseDate!.isNotEmpty) {
      return releaseDate!.substring(0, 4);
    }
    return 'N/A';
  }

  // Create a copy of Movie with modified fields
  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<String>? genres,
    int? runtime,
    String? director,
    List<String>? cast,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      director: director ?? this.director,
      cast: cast ?? this.cast,
    );
  }
}
