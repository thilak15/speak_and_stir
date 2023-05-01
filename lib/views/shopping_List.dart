import 'package:flutter/material.dart';
import 'package:speak_and_stir/models/ingredient.dart';

class ShoppingListPage extends StatefulWidget {
  final List<Ingredient> unavailableIngredients;

  ShoppingListPage({required this.unavailableIngredients});

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: widget.unavailableIngredients.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text('${index + 1}.'),
            title: Text(widget.unavailableIngredients[index].name),
          );
        },
      ),
    );
  }
}
