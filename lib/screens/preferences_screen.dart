import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/providers/auth_provider.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/widgets/genre_selector.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PreferencesProvider>(context, listen: false).loadUserPreferences();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preferences: ${e.toString()}'),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(
            title: 'Your Preferences',
            showBackButton: false,
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: LoadingWidget(),
              ),
            )
          else
            SliverFillRemaining(
              child: Column(
                children: [
                  _buildUserInfo(authProvider),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Favorite Movies'),
                      Tab(text: 'Watched Movies'),
                      Tab(text: 'Genres'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFavoritesTab(preferencesProvider),
                        _buildWatchedTab(preferencesProvider),
                        _buildGenresTab(preferencesProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user?.email ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Personalize your movie experience',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              authProvider.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(PreferencesProvider preferencesProvider) {
    final favoriteMovies = preferencesProvider.favoriteMovies;

    return favoriteMovies.isEmpty
        ? _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Favorite Movies',
            message: 'Add movies to your favorites to see them here.',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favoriteMovies.length,
            itemBuilder: (context, index) {
              return _buildMovieListItem(
                favoriteMovies[index],
                onRemove: () =>
                    preferencesProvider.removeFavorite(favoriteMovies[index].id),
                isFavorite: true,
              );
            },
          );
  }

  Widget _buildWatchedTab(PreferencesProvider preferencesProvider) {
    final watchedMovies = preferencesProvider.watchedMovies;

    return watchedMovies.isEmpty
        ? _buildEmptyState(
            icon: Icons.visibility_off,
            title: 'No Watched Movies',
            message: 'Mark movies as watched to see them here.',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: watchedMovies.length,
            itemBuilder: (context, index) {
              return _buildMovieListItem(
                watchedMovies[index],
                onRemove: () =>
                    preferencesProvider.removeWatched(watchedMovies[index].id),
                isWatched: true,
              );
            },
          );
  }

  Widget _buildGenresTab(PreferencesProvider preferencesProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Preferred Genres',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          GenreSelector(
            selectedGenres: preferencesProvider.preferredGenres,
            onGenreToggle: (genre, isSelected) {
              if (isSelected) {
                preferencesProvider.addPreferredGenre(genre);
              } else {
                preferencesProvider.removePreferredGenre(genre);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovieListItem(
    Movie movie, {
    required VoidCallback onRemove,
    bool isFavorite = false,
    bool isWatched = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            movie.posterUrl,
            width: 60,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 90,
                color: Colors.grey.shade300,
                child: const Icon(Icons.movie),
              );
            },
          ),
        ),
        title: Text(
          movie.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        subtitle: Text(
          movie.releaseYear,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.visibility,
            color: isFavorite ? Colors.red : Colors.green,
          ),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
