import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class TMDBService {
  final String baseUrl = 'https://api.themoviedb.org/3';
  final String apiKey = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1NzYyNDUzYTRiMWE0ZThhNTgzZTNjNjU3NGJlNTgwMyIsIm5iZiI6MTc0NDAyMTU3My41NTcsInN1YiI6IjY3ZjNhODQ1NmMzNTgzYzk3NTk5MjI5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.JWcyrO_vEOCT8AFyQf66AePsIB3azCUYmrAtvVasIvg';
  
  // Get popular movies
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/popular?language=en-US&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load popular movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch popular movies: ${e.toString()}');
    }
  }

  // Search movies
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/movie?query=${Uri.encodeComponent(query)}&page=$page&language=en-US&include_adult=false'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search movies: ${e.toString()}');
    }
  }

  // Get movie details
  Future<Movie> getMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/$movieId?language=en-US'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromDetailJson(data);
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch movie details: ${e.toString()}');
    }
  }

  // Get movies by genre
  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discover/movie?language=en-US&with_genres=$genreId&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load movies by genre: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch movies by genre: ${e.toString()}');
    }
  }

  // Get genres list
  Future<List<Map<String, dynamic>>> getGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/genre/movie/list?language=en-US'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['genres']);
      } else {
        throw Exception('Failed to load genres: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch genres: ${e.toString()}');
    }
  }

  // Get top rated movies
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/top_rated?language=en-US&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load top rated movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch top rated movies: ${e.toString()}');
    }
  }

  // Get similar movies
  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/$movieId/similar?language=en-US&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load similar movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch similar movies: ${e.toString()}');
    }
  }

  // Get movie recommendations
  Future<List<Movie>> getRecommendations(int movieId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/$movieId/recommendations?language=en-US&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load movie recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch movie recommendations: ${e.toString()}');
    }
  }

  // Get now playing movies
  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/now_playing?language=en-US&page=$page'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json;charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load now playing movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch now playing movies: ${e.toString()}');
    }
  }
}
