import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final double width;
  final double? height;
  final bool isFavorite;
  final bool isWatched;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onWatchedToggle;
  final bool showTitle;
  final bool showRating;

  const MovieCard({
    Key? key,
    required this.movie,
    this.width = 150.0,
    this.height,
    this.isFavorite = false,
    this.isWatched = false,
    required this.onTap,
    this.onFavoriteToggle,
    this.onWatchedToggle,
    this.showTitle = false,
    this.showRating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              // Movie poster
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'movie_${movie.id}',
                      child: Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.movie, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Show title if needed
                  if (showTitle)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (showRating && movie.voteAverage > 0) ...[
                            const SizedBox(height: 4.0),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16.0,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Favorites and watched buttons
              if (onFavoriteToggle != null || onWatchedToggle != null)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Column(
                    children: [
                      if (onFavoriteToggle != null)
                        _buildActionButton(
                          icon: isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          onTap: onFavoriteToggle!,
                        ),
                      if (onWatchedToggle != null) ...[
                        const SizedBox(height: 8.0),
                        _buildActionButton(
                          icon: isWatched
                              ? Icons.visibility
                              : Icons.visibility_outlined,
                          color: isWatched ? Colors.green : Colors.white,
                          onTap: onWatchedToggle!,
                        ),
                      ],
                    ],
                  ),
                ),
              // Release year
              if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty && !showTitle)
                Positioned(
                  bottom: 8.0,
                  left: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      movie.releaseYear,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: color,
            size: 20.0,
          ),
        ),
      ),
    );
  }
}
