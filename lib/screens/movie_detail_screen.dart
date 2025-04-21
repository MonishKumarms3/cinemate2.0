import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/services/tmdb_service.dart';
import 'package:movie_recommendation_app/widgets/movie_card.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({
    Key? key,
    required this.movieId,
  }) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = true;
  Movie? _movie;
  List<Movie> _similarMovies = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load movie details
      final movie = await _tmdbService.getMovieDetails(widget.movieId);
      setState(() {
        _movie = movie;
      });

      // Load similar movies
      final similarMovies = await _tmdbService.getSimilarMovies(widget.movieId);
      setState(() {
        _similarMovies = similarMovies;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load movie details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _loadMovieDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _movie == null
                  ? const Center(child: Text('Movie not found'))
                  : CustomScrollView(
                      slivers: [
                        _buildAppBar(_movie!, preferencesProvider),
                        SliverToBoxAdapter(
                          child: _buildMovieDetails(_movie!),
                        ),
                        if (_similarMovies.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildSimilarMovies(_similarMovies, preferencesProvider),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildAppBar(Movie movie, PreferencesProvider preferencesProvider) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          movie.title,
          style: const TextStyle(
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              movie.backdropUrl,
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            preferencesProvider.isFavorite(movie.id)
                ? Icons.favorite
                : Icons.favorite_border,
            color: preferencesProvider.isFavorite(movie.id)
                ? Colors.red
                : Colors.white,
          ),
          onPressed: () {
            if (preferencesProvider.isFavorite(movie.id)) {
              preferencesProvider.removeFavorite(movie.id);
            } else {
              preferencesProvider.addFavorite(movie);
            }
          },
          tooltip: 'Add to favorites',
        ),
        IconButton(
          icon: Icon(
            preferencesProvider.isWatched(movie.id)
                ? Icons.visibility
                : Icons.visibility_outlined,
            color: preferencesProvider.isWatched(movie.id)
                ? Colors.green
                : Colors.white,
          ),
          onPressed: () {
            if (preferencesProvider.isWatched(movie.id)) {
              preferencesProvider.removeWatched(movie.id);
            } else {
              preferencesProvider.addWatched(movie);
            }
          },
          tooltip: 'Mark as watched',
        ),
      ],
    );
  }

  Widget _buildMovieDetails(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  movie.posterUrl,
                  width: 120,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16.0),
              // Movie details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    if (movie.releaseDate != null) ...[
                      Text(
                        'Release Date: ${movie.releaseDate}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4.0),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18.0),
                        const SizedBox(width: 4.0),
                        Text(
                          '${movie.voteAverage.toStringAsFixed(1)}/10',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '(${movie.voteCount} votes)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (movie.genres != null && movie.genres!.isNotEmpty) ...[
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: movie.genres!.map((genre) {
                          return Chip(
                            label: Text(
                              genre,
                              style: const TextStyle(fontSize: 12.0),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          // Overview
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          Text(
            movie.overview,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24.0),
          // Director and Cast
          if (movie.director != null || (movie.cast != null && movie.cast!.isNotEmpty)) ...[
            Text(
              'Credits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            if (movie.director != null) ...[
              Text(
                'Director: ${movie.director}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4.0),
            ],
            if (movie.cast != null && movie.cast!.isNotEmpty) ...[
              Text(
                'Cast: ${movie.cast!.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24.0),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarMovies(
      List<Movie> similarMovies, PreferencesProvider preferencesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Similar Movies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: similarMovies.length,
            itemBuilder: (context, index) {
              final movie = similarMovies[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
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
        const SizedBox(height: 24.0),
      ],
    );
  }
}
