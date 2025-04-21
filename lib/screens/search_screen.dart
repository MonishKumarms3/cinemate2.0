import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/widgets/movie_card.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/screens/movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<MovieProvider>(context, listen: false)
          .searchMovies(_searchQuery);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching movies: ${e.toString()}'),
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
    final movieProvider = Provider.of<MovieProvider>(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(
            title: 'Search Movies',
            showBackButton: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for movies...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _searchQuery.isEmpty ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isLoading
                        ? const LoadingWidget(size: 24.0)
                        : const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: LoadingWidget(),
              ),
            )
          else if (movieProvider.searchResults.isEmpty && _searchQuery.isNotEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No movies found'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = movieProvider.searchResults[index];
                    return MovieCard(
                      movie: movie,
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
                    );
                  },
                  childCount: movieProvider.searchResults.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
