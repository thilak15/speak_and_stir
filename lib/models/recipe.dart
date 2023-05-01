import 'ingredient.dart';

class Recipe {
  final String id;
  final String title;
  final String origin;
  final String type;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String preparationTime;
  final String cookingTime;

  Recipe({
    required this.id,
    required this.title,
    required this.origin,
    required this.type,
    required this.ingredients,
    required String stepsText,
    required this.preparationTime,
    required this.cookingTime,
  }) : steps = _parseSteps(stepsText);

  static List<String> _parseSteps(String stepsText) {
    List<String> steps = stepsText.split(RegExp(r'(?<!\d)\.')).where((step) => step.trim().isNotEmpty).toList();

    for (int i = 0; i < steps.length; i++) {
      steps[i] = steps[i].trim();
    }

    return steps;
  }
}
