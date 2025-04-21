import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_recommendation_app/models/user_preferences.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Create initial user preferences in Firestore
      await _firestore.collection('userPreferences').doc(userCredential.user!.uid).set({
        'favoriteMovies': [],
        'watchedMovies': [],
        'preferredGenres': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get user preferences
  Future<UserPreferences> getUserPreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('userPreferences')
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        // Create preferences if they don't exist
        await _firestore.collection('userPreferences').doc(userId).set({
          'favoriteMovies': [],
          'watchedMovies': [],
          'preferredGenres': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        return UserPreferences(
          favoriteMovies: [],
          watchedMovies: [],
          preferredGenres: [],
        );
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return UserPreferences(
        favoriteMovies: List<Movie>.from((data['favoriteMovies'] ?? []).map(
          (movie) => Movie.fromMap(movie as Map<String, dynamic>))),
        watchedMovies: List<Movie>.from((data['watchedMovies'] ?? []).map(
          (movie) => Movie.fromMap(movie as Map<String, dynamic>))),
        preferredGenres: List<String>.from(data['preferredGenres'] ?? []),
      );
    } catch (e) {
      throw Exception('Failed to get user preferences: ${e.toString()}');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(
      String userId, UserPreferences preferences) async {
    try {
      await _firestore.collection('userPreferences').doc(userId).update({
        'favoriteMovies': preferences.favoriteMovies.map((m) => m.toMap()).toList(),
        'watchedMovies': preferences.watchedMovies.map((m) => m.toMap()).toList(),
        'preferredGenres': preferences.preferredGenres,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user preferences: ${e.toString()}');
    }
  }

  // Add movie to favorites
  Future<void> addFavoriteMovie(String userId, Movie movie) async {
    try {
      await _firestore.collection('userPreferences').doc(userId).update({
        'favoriteMovies': FieldValue.arrayUnion([movie.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add favorite movie: ${e.toString()}');
    }
  }

  // Remove movie from favorites
  Future<void> removeFavoriteMovie(String userId, int movieId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('userPreferences')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> favorites = data['favoriteMovies'] ?? [];
        
        int indexToRemove = favorites.indexWhere(
            (movie) => (movie as Map<String, dynamic>)['id'] == movieId);
        
        if (indexToRemove != -1) {
          favorites.removeAt(indexToRemove);
          await _firestore.collection('userPreferences').doc(userId).update({
            'favoriteMovies': favorites,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to remove favorite movie: ${e.toString()}');
    }
  }

  // Add movie to watched
  Future<void> addWatchedMovie(String userId, Movie movie) async {
    try {
      await _firestore.collection('userPreferences').doc(userId).update({
        'watchedMovies': FieldValue.arrayUnion([movie.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add watched movie: ${e.toString()}');
    }
  }

  // Remove movie from watched
  Future<void> removeWatchedMovie(String userId, int movieId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('userPreferences')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> watched = data['watchedMovies'] ?? [];
        
        int indexToRemove = watched.indexWhere(
            (movie) => (movie as Map<String, dynamic>)['id'] == movieId);
        
        if (indexToRemove != -1) {
          watched.removeAt(indexToRemove);
          await _firestore.collection('userPreferences').doc(userId).update({
            'watchedMovies': watched,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to remove watched movie: ${e.toString()}');
    }
  }

  // Update preferred genres
  Future<void> updatePreferredGenres(String userId, List<String> genres) async {
    try {
      await _firestore.collection('userPreferences').doc(userId).update({
        'preferredGenres': genres,
      });
    } catch (e) {
      throw Exception('Failed to update preferred genres: ${e.toString()}');
    }
  }
}
