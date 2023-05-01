import 'package:flutter/material.dart';
import 'package:speak_and_stir/models/recipe.dart';

class RecipeDetail extends StatelessWidget {
  final Recipe recipe;

  RecipeDetail({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Recipe details for ${recipe.title}'),
            SizedBox(height: 10),
            Text('Preparation time: ${recipe.preparationTime}'),
            SizedBox(height: 10),
            Text('Cooking time: ${recipe.cookingTime}'),
          ],
        ),
      ),
    );
  }
}
