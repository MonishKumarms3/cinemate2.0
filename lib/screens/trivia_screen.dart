import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/services/ai_service.dart';
import 'package:movie_recommendation_app/services/tmdb_service.dart';
import 'package:movie_recommendation_app/widgets/custom_app_bar.dart';
import 'package:movie_recommendation_app/widgets/loading_widget.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/trivia_question.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/providers/preferences_provider.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({Key? key}) : super(key: key);

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> with AutomaticKeepAliveClientMixin {
  final AIService _aiService = AIService();
  final TMDBService _tmdbService = TMDBService();
  
  bool _isLoading = false;
  bool _isGeneratingTrivia = false;
  Movie? _selectedMovie;
  List<TriviaQuestion> _triviaQuestions = [];
  Map<int, int> _userAnswers = {};
  bool _quizSubmitted = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMoviesList();
    });
  }

  Future<void> _initializeMoviesList() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    if (movieProvider.popularMovies.isEmpty) {
      await movieProvider.loadPopularMovies();
    }
  }

  Future<void> _generateTrivia() async {
    if (_selectedMovie == null) {
      setState(() {
        _errorMessage = 'Please select a movie first';
      });
      return;
    }

    setState(() {
      _isGeneratingTrivia = true;
      _errorMessage = '';
      _triviaQuestions = [];
      _userAnswers = {};
      _quizSubmitted = false;
    });

    try {
      // Get detailed movie info if needed
      Movie detailedMovie = _selectedMovie!;
      if (_selectedMovie!.overview.isEmpty) {
        detailedMovie = await _tmdbService.getMovieDetails(_selectedMovie!.id);
      }

      // Generate trivia questions
      final questions = await _aiService.generateMovieTrivia(detailedMovie.title);
      
      setState(() {
        _triviaQuestions = questions;
        _isGeneratingTrivia = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate trivia: ${e.toString()}';
        _isGeneratingTrivia = false;
      });
    }
  }

  void _selectAnswer(int questionIndex, int answerIndex) {
    if (!_quizSubmitted) {
      setState(() {
        _userAnswers[questionIndex] = answerIndex;
      });
    }
  }

  void _submitQuiz() {
    setState(() {
      _quizSubmitted = true;
    });
  }

  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < _triviaQuestions.length; i++) {
      if (_userAnswers[i] == _triviaQuestions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final movieProvider = Provider.of<MovieProvider>(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);

    // Combine movies from different sources for the dropdown
    final List<Movie> movieOptions = [
      ...preferencesProvider.favoriteMovies,
      ...movieProvider.popularMovies,
    ];
    
    // Remove duplicates
    final Map<int, Movie> uniqueMovies = {};
    for (var movie in movieOptions) {
      uniqueMovies[movie.id] = movie;
    }
    
    final List<Movie> finalMovieOptions = uniqueMovies.values.toList();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(
            title: 'Movie Trivia',
            showBackButton: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Movie Trivia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Select a movie and generate five trivia questions to test your knowledge!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16.0),
                  if (movieProvider.isLoading)
                    const Center(child: LoadingWidget())
                  else
                    _buildMovieDropdown(finalMovieOptions),
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
                      onPressed: _isGeneratingTrivia || _selectedMovie == null 
                          ? null 
                          : _generateTrivia,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isGeneratingTrivia
                          ? const LoadingWidget(size: 24.0)
                          : const Text('Generate Trivia'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isGeneratingTrivia)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingWidget(),
                    SizedBox(height: 16.0),
                    Text('Generating trivia questions...'),
                  ],
                ),
              ),
            )
          else if (_triviaQuestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildTriviaQuiz(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieDropdown(List<Movie> movies) {
    return DropdownButtonFormField<Movie>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: 'Select a movie',
      ),
      value: _selectedMovie,
      items: movies.map((movie) {
        return DropdownMenuItem<Movie>(
          value: movie,
          child: Text(
            movie.title,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (Movie? newValue) {
        setState(() {
          _selectedMovie = newValue;
          _triviaQuestions = [];
          _userAnswers = {};
          _quizSubmitted = false;
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildTriviaQuiz() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trivia Quiz: ${_selectedMovie?.title}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        ...List.generate(
          _triviaQuestions.length,
          (index) => _buildQuestionCard(index),
        ),
        const SizedBox(height: 24.0),
        if (!_quizSubmitted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userAnswers.length == _triviaQuestions.length
                  ? _submitQuiz
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Submit Answers'),
            ),
          ),
        ] else ...[
          _buildQuizResults(),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _triviaQuestions[questionIndex];
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1}: ${question.questionText}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            ...List.generate(
              question.options.length,
              (optionIndex) => _buildAnswerOption(
                questionIndex,
                optionIndex,
                question.options[optionIndex],
                isCorrect: _quizSubmitted &&
                    question.correctAnswerIndex == optionIndex,
                isWrong: _quizSubmitted &&
                    _userAnswers[questionIndex] == optionIndex &&
                    question.correctAnswerIndex != optionIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(
    int questionIndex,
    int optionIndex,
    String optionText, {
    bool isCorrect = false,
    bool isWrong = false,
  }) {
    return InkWell(
      onTap: () => _selectAnswer(questionIndex, optionIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: _getOptionColor(
              questionIndex, optionIndex, isCorrect, isWrong),
          border: Border.all(
            color: _userAnswers[questionIndex] == optionIndex
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: _userAnswers[questionIndex] == optionIndex ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            _buildOptionIndicator(questionIndex, optionIndex, isCorrect, isWrong),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontWeight: _userAnswers[questionIndex] == optionIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionIndicator(
    int questionIndex,
    int optionIndex,
    bool isCorrect,
    bool isWrong,
  ) {
    if (_quizSubmitted) {
      if (isCorrect) {
        return const Icon(Icons.check_circle, color: Colors.green);
      }
      if (isWrong) {
        return const Icon(Icons.cancel, color: Colors.red);
      }
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _userAnswers[questionIndex] == optionIndex
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        color: _userAnswers[questionIndex] == optionIndex
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
      ),
      child: _userAnswers[questionIndex] == optionIndex
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Color _getOptionColor(
    int questionIndex,
    int optionIndex,
    bool isCorrect,
    bool isWrong,
  ) {
    if (_quizSubmitted) {
      if (isCorrect) {
        return Colors.green.withOpacity(0.2);
      }
      if (isWrong) {
        return Colors.red.withOpacity(0.2);
      }
    }
    
    return _userAnswers[questionIndex] == optionIndex
        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
        : Colors.transparent;
  }

  Widget _buildQuizResults() {
    final score = _calculateScore();
    final total = _triviaQuestions.length;
    final percentage = (score / total) * 100;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Quiz Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16.0),
            Text(
              '$score/$total correct (${percentage.toInt()}%)',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _getScoreMessage(percentage),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: _generateTrivia,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreMessage(double percentage) {
    if (percentage == 100) {
      return 'Perfect! You\'re a true movie buff!';
    } else if (percentage >= 80) {
      return 'Great job! You really know your movies!';
    } else if (percentage >= 60) {
      return 'Good effort! You\'re on your way to becoming a movie expert.';
    } else if (percentage >= 40) {
      return 'Not bad, but there\'s room for improvement.';
    } else {
      return 'Keep watching more movies to improve your knowledge!';
    }
  }
}
