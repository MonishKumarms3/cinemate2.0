import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/services/tmdb_service.dart';

class MovieProvider with ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _nowPlayingMovies = [];
  List<Movie> _searchResults = [];
  List<Map<String, dynamic>> _genres = [];
  
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get searchResults => _searchResults;
  List<Map<String, dynamic>> get genres => _genres;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load popular movies
  Future<void> loadPopularMovies() async {
    if (_popularMovies.isNotEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final movies = await _tmdbService.getPopularMovies();
      _popularMovies = movies;
    } catch (e) {
      _errorMessage = 'Failed to load popular movies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load top rated movies
  Future<void> loadTopRatedMovies() async {
    if (_topRatedMovies.isNotEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final movies = await _tmdbService.getTopRatedMovies();
      _topRatedMovies = movies;
    } catch (e) {
      _errorMessage = 'Failed to load top rated movies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load now playing movies
  Future<void> loadNowPlayingMovies() async {
    if (_nowPlayingMovies.isNotEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final movies = await _tmdbService.getNowPlayingMovies();
      _nowPlayingMovies = movies;
    } catch (e) {
      _errorMessage = 'Failed to load now playing movies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search movies
  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final movies = await _tmdbService.searchMovies(query);
      _searchResults = movies;
    } catch (e) {
      _errorMessage = 'Failed to search movies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load genres
  Future<void> loadGenres() async {
    if (_genres.isNotEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final genres = await _tmdbService.getGenres();
      _genres = genres;
    } catch (e) {
      _errorMessage = 'Failed to load genres: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get movie details
  Future<Movie> getMovieDetails(int movieId) async {
    try {
      return await _tmdbService.getMovieDetails(movieId);
    } catch (e) {
      _errorMessage = 'Failed to get movie details: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Get movie by ID from various sources
  Movie? getMovieById(int movieId) {
    // Check in popular movies
    final popularMovie = _popularMovies.where((m) => m.id == movieId).toList();
    if (popularMovie.isNotEmpty) return popularMovie.first;

    // Check in top rated movies
    final topRatedMovie = _topRatedMovies.where((m) => m.id == movieId).toList();
    if (topRatedMovie.isNotEmpty) return topRatedMovie.first;

    // Check in now playing movies
    final nowPlayingMovie = _nowPlayingMovies.where((m) => m.id == movieId).toList();
    if (nowPlayingMovie.isNotEmpty) return nowPlayingMovie.first;

    // Check in search results
    final searchMovie = _searchResults.where((m) => m.id == movieId).toList();
    if (searchMovie.isNotEmpty) return searchMovie.first;

    return null;
  }

  // Refresh all movie data
  Future<void> refreshMovies() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final popularMovies = await _tmdbService.getPopularMovies();
      _popularMovies = popularMovies;
      
      final topRatedMovies = await _tmdbService.getTopRatedMovies();
      _topRatedMovies = topRatedMovies;
      
      final nowPlayingMovies = await _tmdbService.getNowPlayingMovies();
      _nowPlayingMovies = nowPlayingMovies;
    } catch (e) {
      _errorMessage = 'Failed to refresh movies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
