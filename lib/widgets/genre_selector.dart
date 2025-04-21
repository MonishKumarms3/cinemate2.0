import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/services/tmdb_service.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';

class GenreSelector extends StatefulWidget {
  final List<String> selectedGenres;
  final Function(String, bool) onGenreToggle;

  const GenreSelector({
    Key? key,
    required this.selectedGenres,
    required this.onGenreToggle,
  }) : super(key: key);

  @override
  State<GenreSelector> createState() => _GenreSelectorState();
}

class _GenreSelectorState extends State<GenreSelector> {
  final TMDBService _tmdbService = TMDBService();
  List<Map<String, dynamic>> _genres = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final genres = await _tmdbService.getGenres();
      setState(() {
        _genres = genres;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load genres: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
              onPressed: _loadGenres,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _genres.map((genre) {
        final genreName = genre['name'] as String;
        final isSelected = widget.selectedGenres.contains(genreName);
        
        return FilterChip(
          label: Text(genreName),
          selected: isSelected,
          onSelected: (selected) {
            widget.onGenreToggle(genreName, selected);
          },
          avatar: isSelected ? const Icon(Icons.check, size: 18.0) : null,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
