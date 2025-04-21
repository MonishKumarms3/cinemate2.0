import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/user_preferences.dart';
import 'package:movie_recommendation_app/services/firebase_service.dart';
import 'package:movie_recommendation_app/services/tmdb_service.dart';

class PreferencesProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final TMDBService _tmdbService = TMDBService();
  
  User? _user;
  UserPreferences _preferences = UserPreferences.empty();
  List<Movie> _recommendedMovies = [];
  List<Movie> _recommendedMoviesByGenre = [];
  List<Movie> _recommendedMoviesByFavorites = [];
  List<Movie> _recommendedMoviesByWatched = [];
  
  bool _isLoading = false;
  String _errorMessage = '';

  // Constructor
  PreferencesProvider(this._user) {
    if (_user != null) {
      loadUserPreferences();
    }
  }

  // Getters
  UserPreferences get preferences => _preferences;
  List<Movie> get favoriteMovies => _preferences.favoriteMovies;
  List<Movie> get watchedMovies => _preferences.watchedMovies;
  List<String> get preferredGenres => _preferences.preferredGenres;
  List<Movie> get recommendedMovies => _recommendedMovies;
  List<Movie> get recommendedMoviesByGenre => _recommendedMoviesByGenre;
  List<Movie> get recommendedMoviesByFavorites => _recommendedMoviesByFavorites;
  List<Movie> get recommendedMoviesByWatched => _recommendedMoviesByWatched;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasPreferences => 
      _preferences.favoriteMovies.isNotEmpty || 
      _preferences.watchedMovies.isNotEmpty || 
      _preferences.preferredGenres.isNotEmpty;

  // Check if a movie is in favorites
  bool isFavorite(int movieId) {
    return _preferences.isFavorite(movieId);
  }

  // Check if a movie is watched
  bool isWatched(int movieId) {
    return _preferences.isWatched(movieId);
  }

  // Load user preferences from Firebase
  Future<void> loadUserPreferences() async {
    if (_user == null) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final preferences = await _firebaseService.getUserPreferences(_user!.uid);
      _preferences = preferences;
    } catch (e) {
      _errorMessage = 'Failed to load preferences: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save user preferences to Firebase
  Future<void> saveUserPreferences() async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.updateUserPreferences(_user!.uid, _preferences);
    } catch (e) {
      _errorMessage = 'Failed to save preferences: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add movie to favorites
  Future<void> addFavorite(Movie movie) async {
    if (_user == null) return;
    
    _preferences.addFavorite(movie);
    notifyListeners();

    try {
      await _firebaseService.addFavoriteMovie(_user!.uid, movie);
    } catch (e) {
      // Revert changes on error
      _preferences.removeFavorite(movie.id);
      _errorMessage = 'Failed to add favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  // Remove movie from favorites
  Future<void> removeFavorite(int movieId) async {
    if (_user == null) return;
    
    // Store movie for potential rollback
    final movieToRemove = _preferences.favoriteMovies.firstWhere(
      (movie) => movie.id == movieId,
      orElse: () => Movie(id: 0, title: '', overview: ''),
    );
    
    _preferences.removeFavorite(movieId);
    notifyListeners();

    try {
      await _firebaseService.removeFavoriteMovie(_user!.uid, movieId);
    } catch (e) {
      // Revert changes on error
      if (movieToRemove.id != 0) {
        _preferences.addFavorite(movieToRemove);
      }
      _errorMessage = 'Failed to remove favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  // Add movie to watched
  Future<void> addWatched(Movie movie) async {
    if (_user == null) return;
    
    _preferences.addWatched(movie);
    notifyListeners();

    try {
      await _firebaseService.addWatchedMovie(_user!.uid, movie);
    } catch (e) {
      // Revert changes on error
      _preferences.removeWatched(movie.id);
      _errorMessage = 'Failed to add watched movie: ${e.toString()}';
      notifyListeners();
    }
  }

  // Remove movie from watched
  Future<void> removeWatched(int movieId) async {
    if (_user == null) return;
    
    // Store movie for potential rollback
    final movieToRemove = _preferences.watchedMovies.firstWhere(
      (movie) => movie.id == movieId,
      orElse: () => Movie(id: 0, title: '', overview: ''),
    );
    
    _preferences.removeWatched(movieId);
    notifyListeners();

    try {
      await _firebaseService.removeWatchedMovie(_user!.uid, movieId);
    } catch (e) {
      // Revert changes on error
      if (movieToRemove.id != 0) {
        _preferences.addWatched(movieToRemove);
      }
      _errorMessage = 'Failed to remove watched movie: ${e.toString()}';
      notifyListeners();
    }
  }

  // Add preferred genre
  Future<void> addPreferredGenre(String genre) async {
    if (_user == null) return;
    
    _preferences.addPreferredGenre(genre);
    notifyListeners();

    try {
      await _firebaseService.updatePreferredGenres(_user!.uid, _preferences.preferredGenres);
    } catch (e) {
      // Revert changes on error
      _preferences.removePreferredGenre(genre);
      _errorMessage = 'Failed to add genre preference: ${e.toString()}';
      notifyListeners();
    }
  }

  // Remove preferred genre
  Future<void> removePreferredGenre(String genre) async {
    if (_user == null) return;
    
    _preferences.removePreferredGenre(genre);
    notifyListeners();

    try {
      await _firebaseService.updatePreferredGenres(_user!.uid, _preferences.preferredGenres);
    } catch (e) {
      // Revert changes on error
      _preferences.addPreferredGenre(genre);
      _errorMessage = 'Failed to remove genre preference: ${e.toString()}';
      notifyListeners();
    }
  }

  // Load recommendations based on user preferences
  Future<void> loadRecommendations() async {
    if (_user == null) return;
    
    _isLoading = true;
    _errorMessage = '';
    _recommendedMovies = [];
    _recommendedMoviesByGenre = [];
    _recommendedMoviesByFavorites = [];
    _recommendedMoviesByWatched = [];
    notifyListeners();

    try {
      // Get recommendations based on genres
      if (_preferences.preferredGenres.isNotEmpty) {
        await _loadRecommendationsByGenre();
      }
      
      // Get recommendations based on favorite movies
      if (_preferences.favoriteMovies.isNotEmpty) {
        await _loadRecommendationsByFavorites();
      }
      
      // Get recommendations based on watch history
      if (_preferences.watchedMovies.isNotEmpty) {
        await _loadRecommendationsByWatched();
      }
      
      // Combine all recommendations and remove duplicates
      _combineRecommendations();
    } catch (e) {
      _errorMessage = 'Failed to load recommendations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recommendations based on preferred genres
  Future<void> _loadRecommendationsByGenre() async {
    try {
      // Get genre IDs from genre names
      final genreList = await _tmdbService.getGenres();
      final Map<String, int> genreMap = {};
      
      for (var genre in genreList) {
        genreMap[genre['name']] = genre['id'];
      }
      
      List<Movie> recommendations = [];
      
      // Get movies for each preferred genre
      for (var genreName in _preferences.preferredGenres) {
        if (genreMap.containsKey(genreName)) {
          final genreId = genreMap[genreName]!;
          final movies = await _tmdbService.getMoviesByGenre(genreId);
          recommendations.addAll(movies);
        }
      }
      
      // Remove duplicates
      final Map<int, Movie> uniqueMovies = {};
      for (var movie in recommendations) {
        uniqueMovies[movie.id] = movie;
      }
      
      _recommendedMoviesByGenre = uniqueMovies.values.toList();
      
      // Limit to 20 movies
      if (_recommendedMoviesByGenre.length > 20) {
        _recommendedMoviesByGenre = _recommendedMoviesByGenre.sublist(0, 20);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Load recommendations based on favorite movies
  Future<void> _loadRecommendationsByFavorites() async {
    try {
      List<Movie> recommendations = [];
      
      // Get recommendations for each favorite movie
      for (var movie in _preferences.favoriteMovies.take(3)) {
        final similar = await _tmdbService.getSimilarMovies(movie.id);
        recommendations.addAll(similar);
      }
      
      // Remove duplicates
      final Map<int, Movie> uniqueMovies = {};
      for (var movie in recommendations) {
        uniqueMovies[movie.id] = movie;
      }
      
      _recommendedMoviesByFavorites = uniqueMovies.values.toList();
      
      // Limit to 20 movies
      if (_recommendedMoviesByFavorites.length > 20) {
        _recommendedMoviesByFavorites = _recommendedMoviesByFavorites.sublist(0, 20);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Load recommendations based on watched movies
  Future<void> _loadRecommendationsByWatched() async {
    try {
      List<Movie> recommendations = [];
      
      // Get recommendations for each watched movie
      for (var movie in _preferences.watchedMovies.take(3)) {
        final similar = await _tmdbService.getRecommendations(movie.id);
        recommendations.addAll(similar);
      }
      
      // Remove duplicates
      final Map<int, Movie> uniqueMovies = {};
      for (var movie in recommendations) {
        uniqueMovies[movie.id] = movie;
      }
      
      _recommendedMoviesByWatched = uniqueMovies.values.toList();
      
      // Limit to 20 movies
      if (_recommendedMoviesByWatched.length > 20) {
        _recommendedMoviesByWatched = _recommendedMoviesByWatched.sublist(0, 20);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Combine all recommendations and remove duplicates
  void _combineRecommendations() {
    List<Movie> allRecommendations = [
      ..._recommendedMoviesByGenre,
      ..._recommendedMoviesByFavorites,
      ..._recommendedMoviesByWatched,
    ];
    
    // Remove duplicates
    final Map<int, Movie> uniqueMovies = {};
    for (var movie in allRecommendations) {
      uniqueMovies[movie.id] = movie;
    }
    
    // Remove movies that are already in favorites or watched
    for (var movie in _preferences.favoriteMovies) {
      uniqueMovies.remove(movie.id);
    }
    for (var movie in _preferences.watchedMovies) {
      uniqueMovies.remove(movie.id);
    }
    
    _recommendedMovies = uniqueMovies.values.toList();
  }
}
