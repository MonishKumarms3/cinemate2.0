import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/services/ai_service.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/widgets/movie_card.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';
import 'package:movie_recommendation_app/screens/movie_detail_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({Key? key}) : super(key: key);

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _plotController = TextEditingController();
  final AIService _aiService = AIService();
  List<Movie> _predictedMovies = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _plotController.dispose();
    super.dispose();
  }

  Future<void> _predictMovies() async {
    final plot = _plotController.text.trim();
    if (plot.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a plot description';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final movies = await _aiService.predictMoviesFromPlot(plot);
      setState(() {
        _predictedMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to predict movies: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(
            title: 'AI Movie Prediction',
            showBackButton: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe a Movie Plot',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Enter a movie plot or scenario, and our AI will recommend similar movies.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _plotController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'E.g., A young wizard discovers he has magical powers and is invited to attend a school for wizards...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _predictMovies,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isLoading
                          ? const LoadingWidget(size: 24.0)
                          : const Text('Predict Movies'),
                    ),
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
          else if (_predictedMovies.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'AI Recommendations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  ...List.generate(
                    _predictedMovies.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildMovieCard(
                        _predictedMovies[index],
                        preferencesProvider,
                      ),
                    ),
                  ),
                ]),
              ),
            )
          else if (_plotController.text.isNotEmpty &&
              !_isLoading &&
              _predictedMovies.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No predictions found. Try a different plot description.'),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildExampleSection(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, PreferencesProvider preferencesProvider) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    movie.posterUrl,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.movie, size: 50),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        movie.overview,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  preferencesProvider.isFavorite(movie.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: preferencesProvider.isFavorite(movie.id)
                      ? Colors.red
                      : null,
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
                      : null,
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
          ),
        ],
      ),
    );
  }

  Widget _buildExampleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example Plot Descriptions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        _buildExampleCard(
          'A group of friends goes on a camping trip in the woods, only to discover they are being hunted by a supernatural creature.',
          'Horror / Thriller',
        ),
        const SizedBox(height: 12.0),
        _buildExampleCard(
          'A detective with a troubled past investigates a series of murders that seem to be connected to an ancient ritual.',
          'Mystery / Crime',
        ),
        const SizedBox(height: 12.0),
        _buildExampleCard(
          'Two strangers meet on a train and develop a deep connection as they travel across Europe, knowing they may never see each other again.',
          'Romance / Drama',
        ),
        const SizedBox(height: 12.0),
        _buildExampleCard(
          'In a post-apocalyptic world, a small group of survivors must navigate dangerous territories to find a rumored safe haven.',
          'Sci-Fi / Adventure',
        ),
      ],
    );
  }

  Widget _buildExampleCard(String plotDescription, String genre) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          _plotController.text = plotDescription;
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plotDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                genre,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _plotController.text = plotDescription;
                  },
                  child: const Text('Use this example'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
