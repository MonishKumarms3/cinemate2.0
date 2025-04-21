import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/trivia_question.dart';

class AIService {
  // Gemini API URL
  final String _baseUrl = "https://generativelanguage.googleapis.com/v1beta";
  final String? _apiKey='AIzaSyBJT3UQtp1zCJs0cxwkP-Rb03fSQhPLJzg';
  // Method to predict movies based on plot description
  Future<List<Movie>> predictMoviesFromPlot(String plotDescription) async {


    try {
      final model = "gemini-2.0-flash"; // Using the text-only model
      final prompt = """
      Based on the following plot description, suggest 5 movies that match it. 
      Plot: $plotDescription
      
      Format your response as a JSON array with each movie having these properties:
      - id (a random number)
      - title (the movie title)
      - overview (a brief description)
      - release_date (in YYYY-MM-DD format)
      - genre_ids (an array of genre numbers)
      - vote_average (a rating from 0-10)
      
      Return only the JSON array without any additional text.
      """;

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract the text response from Gemini
        final String textResponse = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Parse the JSON array from the text response
        try {
          // Try to extract just the JSON part (in case there's surrounding text)
          String jsonStr = extractJsonFromText(textResponse);
          final List<dynamic> moviesData = jsonDecode(jsonStr);

          // Convert each item to a Movie object
          return moviesData
              .map((movie) => Movie.fromAIJson(movie as Map<String, dynamic>))
              .toList();
        } catch (jsonError) {
          print('Error parsing JSON from Gemini response: $jsonError');
          print('Raw response: $textResponse');
          throw Exception('Failed to parse movie predictions from AI response');
        }
      } else {
        throw Exception('Failed to predict movies: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // For debugging, print the error
      print('Error in predictMoviesFromPlot: $e');

      // Return an empty list on error
      return [];
    }
  }

  // Method to generate trivia questions for a movie
  Future<List<TriviaQuestion>> generateMovieTrivia(String movieTitle, {int count = 5}) async {


    try {
      final model = "gemini-2.0-flash"; // Using the text-only model
      final prompt = """
      Generate $count trivia questions about the movie "$movieTitle". 
      
      Format your response as a JSON array with each question having these properties:
      - question (the trivia question)
      - correct_answer_index (the correct answer index in the options 0-3)
      - options (an array of 4 possible answers including the correct one)
      
      Return only the JSON array without any additional text.
      """;

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 32,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract the text response from Gemini
        final String textResponse = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Parse the JSON array from the text response
        try {
          // Try to extract just the JSON part (in case there's surrounding text)
          String jsonStr = extractJsonFromText(textResponse);
          final List<dynamic> questionsData = jsonDecode(jsonStr);

          // Convert each item to a TriviaQuestion object
          return questionsData
              .map((q) => TriviaQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
        } catch (jsonError) {
          print('Error parsing JSON from Gemini response: $jsonError');
          print('Raw response: $textResponse');
          throw Exception('Failed to parse trivia questions from AI response');
        }
      } else {
        throw Exception('Failed to generate trivia: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // For debugging, print the error
      print('Error in generateMovieTrivia: $e');

      // Return an empty list on error
      return [];
    }
  }

  // Helper method to extract JSON from text that might contain additional context
  String extractJsonFromText(String text) {
    // Find the first '[' and last ']' to extract the JSON array
    final startIndex = text.indexOf('[');
    final endIndex = text.lastIndexOf(']') + 1;

    if (startIndex >= 0 && endIndex > startIndex) {
      return text.substring(startIndex, endIndex);
    } else if (text.contains('{') && text.contains('}')) {
      // If it's not an array, try to extract an object
      final objStartIndex = text.indexOf('{');
      final objEndIndex = text.lastIndexOf('}') + 1;
      return text.substring(objStartIndex, objEndIndex);
    }

    // If we can't find JSON markers, return the original text
    return text;
  }
}