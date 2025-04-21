class TriviaQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  TriviaQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  // Factory constructor to create TriviaQuestion from JSON
  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      questionText: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correct_answer_index'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
    };
  }

  // Get correct answer
  String get correctAnswer {
    return options[correctAnswerIndex];
  }
}
