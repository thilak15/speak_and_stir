import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speak_and_stir/models/recipe.dart';
import 'package:speak_and_stir/models/ingredient.dart';
import 'dart:async';

class GPTNLP {
  final String apiKey = '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';
  bool _generationInProgress = false;

  Future<String> generateText(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'text-davinci-003',
        'prompt': prompt,
        'max_tokens': 1000,
        'temperature': 0.5,
        'n': 1,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final generatedText = responseData['choices'][0]['text'];
      print('generateText response: $responseData');
      return generatedText;
    } else {
      print('API Response: ${response.body}');
      throw Exception('Failed to generate text');
    }
  }

  Future<List<Recipe>> generateRecipes(String query) async {
    if (_generationInProgress) {
      // If a generation is already in progress, return an empty list
      return [];
    }
    _generationInProgress = true;

    String prompt =
        "Generate a list of 2 recipes with their title, origin, type, preparation time, cooking time, ingredients, and steps separated by commas in the following format: 'Title | Origin | Type | Preparation Time | Cooking Time | Ingredients | Steps' based on the following query: $query";

    String generatedText = await generateText(prompt);
    print('Generated Text: $generatedText');

    List<Recipe> recipes = [];
    int idCounter = 1;
    for (String recipeString in generatedText.split("\n")) {
      if (recipeString.isNotEmpty) {
        List<String> parts = recipeString.split("|");
        if (parts.length == 7) {
          String id = idCounter.toString();
          idCounter++;
          String title = parts[0].trim();
          String origin = parts[1].trim();
          String type = parts[2].trim();
          String preparationTime = parts[3].trim();
          String cookingTime = parts[4].trim();
          List<Ingredient> ingredients = parts[5]
              .split(",")
              .map((ingredient) => Ingredient(name: ingredient.trim(), quantity: '', unit: ''))
              .toList();
          List<String> steps = parts[6].split(',').map((step) => step.trim()).toList();

          recipes.add(Recipe(
            id: id,
            title: title,
            origin: origin,
            type: type,
            ingredients: ingredients,
            stepsText: steps.join(),
            preparationTime: preparationTime,
            cookingTime: cookingTime,
          ));
        }
      }
    }

    _generationInProgress = false;
    return recipes;
  }
}
