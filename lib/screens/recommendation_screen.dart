import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/widgets/movie_card.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/screens/movie_detail_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PreferencesProvider>(context, listen: false)
          .loadRecommendations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recommendations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: CustomScrollView(
          slivers: [
            const CustomAppBar(
              title: 'Recommended For You',
              showBackButton: false,
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: LoadingWidget(),
                ),
              )
            else if (!preferencesProvider.hasPreferences)
              SliverFillRemaining(
                child: _buildNoPreferencesMessage(),
              )
            else if (preferencesProvider.recommendedMovies.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No recommendations found.\nTry adding more favorites or genres.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              // Display recommendations based on genres
              if (preferencesProvider.preferredGenres.isNotEmpty)
                _buildRecommendationSection(
                  context, 
                  'Based on Your Preferred Genres', 
                  preferencesProvider.recommendedMoviesByGenre,
                  preferencesProvider,
                ),
              
              // Display recommendations based on favorites
              if (preferencesProvider.favoriteMovies.isNotEmpty)
                _buildRecommendationSection(
                  context, 
                  'Because You Liked', 
                  preferencesProvider.recommendedMoviesByFavorites,
                  preferencesProvider,
                ),
              
              // Display recommendations based on watch history
              if (preferencesProvider.watchedMovies.isNotEmpty)
                _buildRecommendationSection(
                  context, 
                  'Similar to What You Watched', 
                  preferencesProvider.recommendedMoviesByWatched,
                  preferencesProvider,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoPreferencesMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Get Personalized Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Mark movies as favorites, add to your watch history, or select your preferred genres to receive tailored recommendations.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to preferences screen
                DefaultTabController.of(context)?.animateTo(5);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Go to Preferences'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRecommendationSection(
    BuildContext context,
    String title,
    List<Movie> movies,
    PreferencesProvider preferencesProvider,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 380,
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
                    width: 200,
                    height: 380,
                    isFavorite: preferencesProvider.isFavorite(movie.id),
                    isWatched: preferencesProvider.isWatched(movie.id),
                    showTitle: true,
                    showRating: true,
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
      ),
    );
  }
}
