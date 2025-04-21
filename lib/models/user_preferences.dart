import 'package:movie_recommendation_app/models/movie.dart';

class UserPreferences {
  List<Movie> favoriteMovies;
  List<Movie> watchedMovies;
  List<String> preferredGenres;

  UserPreferences({
    required this.favoriteMovies,
    required this.watchedMovies,
    required this.preferredGenres,
  });

  // Check if a movie is in favorites
  bool isFavorite(int movieId) {
    return favoriteMovies.any((movie) => movie.id == movieId);
  }

  // Check if a movie is in watched
  bool isWatched(int movieId) {
    return watchedMovies.any((movie) => movie.id == movieId);
  }

  // Add movie to favorites
  void addFavorite(Movie movie) {
    if (!isFavorite(movie.id)) {
      favoriteMovies.add(movie);
    }
  }

  // Remove movie from favorites
  void removeFavorite(int movieId) {
    favoriteMovies.removeWhere((movie) => movie.id == movieId);
  }

  // Add movie to watched
  void addWatched(Movie movie) {
    if (!isWatched(movie.id)) {
      watchedMovies.add(movie);
    }
  }

  // Remove movie from watched
  void removeWatched(int movieId) {
    watchedMovies.removeWhere((movie) => movie.id == movieId);
  }

  // Add preferred genre
  void addPreferredGenre(String genre) {
    if (!preferredGenres.contains(genre)) {
      preferredGenres.add(genre);
    }
  }

  // Remove preferred genre
  void removePreferredGenre(String genre) {
    preferredGenres.remove(genre);
  }

  // Create empty preferences
  factory UserPreferences.empty() {
    return UserPreferences(
      favoriteMovies: [],
      watchedMovies: [],
      preferredGenres: [],
    );
  }

  // Create a copy with modified fields
  UserPreferences copyWith({
    List<Movie>? favoriteMovies,
    List<Movie>? watchedMovies,
    List<String>? preferredGenres,
  }) {
    return UserPreferences(
      favoriteMovies: favoriteMovies ?? List.from(this.favoriteMovies),
      watchedMovies: watchedMovies ?? List.from(this.watchedMovies),
      preferredGenres: preferredGenres ?? List.from(this.preferredGenres),
    );
  }
}
