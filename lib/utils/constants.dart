class Constants {
  // API Keys
  static final String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: 'your_tmdb_api_key');
  static final String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'your_openai_api_key');
  
  // Genre categories
  static const Map<String, String> genreIcons = {
    'Action': '⚡',
    'Adventure': '🏔️',
    'Animation': '🎨',
    'Comedy': '😂',
    'Crime': '🔍',
    'Documentary': '📚',
    'Drama': '🎭',
    'Family': '👨‍👩‍👧‍👦',
    'Fantasy': '🧙‍♂️',
    'History': '📜',
    'Horror': '👻',
    'Music': '🎵',
    'Mystery': '🔎',
    'Romance': '💑',
    'Science Fiction': '🚀',
    'TV Movie': '📺',
    'Thriller': '😱',
    'War': '⚔️',
    'Western': '🤠',
  };
  
  // Movie categories
  static const String popularCategory = 'Popular';
  static const String topRatedCategory = 'Top Rated';
  static const String nowPlayingCategory = 'Now Playing';
  static const String upcomingCategory = 'Upcoming';
  
  // Image URLs
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';
  static const String posterSize = 'w500';
  static const String backdropSize = 'w780';
  static const String profileSize = 'w185';
  
  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your internet connection and try again.';
  static const String movieLoadErrorMessage = 'Failed to load movies. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials and try again.';
  static const String generalErrorMessage = 'Something went wrong. Please try again later.';
  
  // App settings
  static const int movieCardAnimationDuration = 300; // milliseconds
  static const double movieCardBorderRadius = 12.0;
  static const double appBarHeight = 56.0;
  
  // Firebase collections
  static const String userPreferencesCollection = 'userPreferences';
  static const String favoriteMoviesField = 'favoriteMovies';
  static const String watchedMoviesField = 'watchedMovies';
  static const String preferredGenresField = 'preferredGenres';
  
  // AI features
  static const int maxAIResponseTokens = 500;
  static const double aiTemperature = 0.7;
  static const String aiModelName = 'gpt-3.5-turbo';
}
