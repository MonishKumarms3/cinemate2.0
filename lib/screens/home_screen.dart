import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/auth_provider.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/screens/search_screen.dart';
import 'package:movie_recommendation_app/screens/recommendation_screen.dart';
import 'package:movie_recommendation_app/screens/ai_prediction_screen.dart';
import 'package:movie_recommendation_app/screens/trivia_screen.dart';
import 'package:movie_recommendation_app/screens/preferences_screen.dart';
import 'package:movie_recommendation_app/screens/movie_detail_screen.dart';
import 'package:movie_recommendation_app/widgets/movie_card.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Load movies when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieProvider>(context, listen: false).loadPopularMovies();
      Provider.of<MovieProvider>(context, listen: false).loadTopRatedMovies();
      Provider.of<MovieProvider>(context, listen: false).loadNowPlayingMovies();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final movieProvider = Provider.of<MovieProvider>(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildHomeContent(movieProvider, preferencesProvider),
          const SearchScreen(),
          const RecommendationScreen(),
          const AIScreen(),
          const TriviaScreen(),
          const PreferencesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'For You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Trivia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Preferences',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(
      MovieProvider movieProvider, PreferencesProvider preferencesProvider) {
    return CustomScrollView(
      slivers: [
        CustomAppBar(
          title: 'Movie Recommendations',
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
            ),
          ],
        ),
        if (movieProvider.isLoading)
          const SliverFillRemaining(
            child: Center(
              child: LoadingWidget(),
            ),
          )
        else ...[
          // Now Playing Movies
          SliverToBoxAdapter(
            child: _buildMovieSection(
              context,
              'Now Playing',
              movieProvider.nowPlayingMovies,
              isLarge: true,
            ),
          ),
          // Popular Movies
          SliverToBoxAdapter(
            child: _buildMovieSection(
              context,
              'Popular Movies',
              movieProvider.popularMovies,
            ),
          ),
          // Top Rated Movies
          SliverToBoxAdapter(
            child: _buildMovieSection(
              context,
              'Top Rated Movies',
              movieProvider.topRatedMovies,
            ),
          ),
          // Recommendation based on user preferences if available
          if (preferencesProvider.hasPreferences)
            SliverToBoxAdapter(
              child: _buildRecommendationPreview(
                context,
                preferencesProvider,
              ),
            ),
          // Additional spacing at the bottom
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ],
    );
  }

  Widget _buildMovieSection(
      BuildContext context, String title, List<Movie> movies,
      {bool isLarge = false}) {
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to a screen showing all movies in this category
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: isLarge ? 280 : 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: MovieCard(
                  movie: movie,
                  width: isLarge ? 180 : 140,
                  isFavorite: preferencesProvider.isFavorite(movie.id),
                  isWatched: preferencesProvider.isWatched(movie.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          movieId: movie.id,
                        ),
                      ),
                    );
                  },
                  onFavoriteToggle: () {
                    if (preferencesProvider.isFavorite(movie.id)) {
                      preferencesProvider.removeFavorite(movie.id);
                    } else {
                      preferencesProvider.addFavorite(movie);
                    }
                  },
                  onWatchedToggle: () {
                    if (preferencesProvider.isWatched(movie.id)) {
                      preferencesProvider.removeWatched(movie.id);
                    } else {
                      preferencesProvider.addWatched(movie);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationPreview(
      BuildContext context, PreferencesProvider preferencesProvider) {
    // Show a preview of recommendations based on user preferences
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to recommendations screen
                  setState(() {
                    _currentIndex = 2;
                    _pageController.jumpToPage(2);
                  });
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        if (preferencesProvider.recommendedMovies.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Add some favorite movies or select genres to get personalized recommendations',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: preferencesProvider.recommendedMovies.length,
              itemBuilder: (context, index) {
                final movie = preferencesProvider.recommendedMovies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: MovieCard(
                    movie: movie,
                    width: 140,
                    isFavorite: preferencesProvider.isFavorite(movie.id),
                    isWatched: preferencesProvider.isWatched(movie.id),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(
                            movieId: movie.id,
                          ),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      if (preferencesProvider.isFavorite(movie.id)) {
                        preferencesProvider.removeFavorite(movie.id);
                      } else {
                        preferencesProvider.addFavorite(movie);
                      }
                    },
                    onWatchedToggle: () {
                      if (preferencesProvider.isWatched(movie.id)) {
                        preferencesProvider.removeWatched(movie.id);
                      } else {
                        preferencesProvider.addWatched(movie);
                      }
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
