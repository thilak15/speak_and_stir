import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speak_and_stir/models/recipe.dart';
import 'package:speak_and_stir/utils/speech_recognition.dart';
import 'package:speak_and_stir/utils/text_to_speech.dart';
import 'package:speak_and_stir/views/step_by_step.dart';
import 'package:speak_and_stir/models/ingredient.dart';
import 'package:speak_and_stir/views/shopping_List.dart';

class IngredientsPage extends StatefulWidget {
  final Recipe recipe;
  final int servingSize;
  

  IngredientsPage({required this.recipe, required this.servingSize});

  @override
  _IngredientsPageState createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  final TextToSpeech _textToSpeech = TextToSpeech();
  final SpeechRecognition _speechRecognition = SpeechRecognition();
  bool _isListening = false;
  bool _hasSpoken = false;
  List<bool> _ingredientAvailability = [];
  List<String> _replacementIngredients = [];

     @override
  void initState() {
    super.initState();
    _speechRecognition.initialize().then((value) async {
      if (value) {
        if (!_hasSpoken) {
          await _textToSpeech.speak(
              "Please confirm the availability of the ingredients for ${widget.recipe.title}. Say the name of each available ingredient to mark them as available. When you are done, say 'continue'.");
          await _textToSpeech.pauseFor(Duration(seconds: 4)); 
          _hasSpoken = true;
        }
        await _textToSpeech.pauseFor(Duration(seconds: 2)); 
        _startListening();
      }
    });
    _ingredientAvailability = List.generate(widget.recipe.ingredients.length, (index) => false);
    _replacementIngredients = List.generate(widget.recipe.ingredients.length, (index) => '');
  }


   void _startListening() async {
    _isListening = true;
    await _speechRecognition.listen(
      onResult: (String result) async {
        if (result.toLowerCase() == "continue") {
          _handleContinue();
        } else {
          final ingredientName = result.trim();
          final ingredientIndex = widget.recipe.ingredients.indexWhere((ingredient) => ingredient.name == ingredientName);
    
          if (ingredientIndex != -1) {
            if (!_ingredientAvailability[ingredientIndex]) {
              setState(() {
                _ingredientAvailability[ingredientIndex] = true;
              });
              await _textToSpeech.speak('$ingredientName marked as available.');
            } else {
              await _textToSpeech.speak('Adding $ingredientName to the shopping list.');
              await _textToSpeech.speak('Finding replacements for the $ingredientName.');
    
              fetchReplacementIngredient(ingredientName).then((replacementIngredientName) {
                setState(() {
                  _replacementIngredients[ingredientIndex] = replacementIngredientName;
                  widget.recipe.ingredients[ingredientIndex].name = replacementIngredientName;
                });
                _textToSpeech.speak('You can replace $ingredientName with $replacementIngredientName.');
              }).catchError((error) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StepByStepPage(recipe: widget.recipe, servingSize: widget.servingSize),
                  ),
                );
              });
            }
          }
        }
      },
      onCancelled: () {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {});
  }



  void _stopListening() async {
    await _speechRecognition.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<String> fetchReplacementIngredient(String ingredientName) async {
    final prompt = 'Find a suitable replacement ingredient for $ingredientName.';
    final apiKey = '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';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
        final body = json.encode({
      'model': 'text-davinci-003',
      'prompt': prompt,
      'temperature': 0.9,
      'max_tokens': 10,
      'n': 1,
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/completions'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      _textToSpeech.speak('Found replacement for $ingredientName.');
      final jsonResponse = json.decode(response.body);
      return jsonResponse['choices'][0]['text'].trim();
    } else {
      _textToSpeech.speak('Did not find any replacement for $ingredientName.');
      throw Exception('Failed to load replacement ingredient');
    }
  }

  Future<void> _handleContinue() async {
    await _speechRecognition.stop();
    List<Ingredient> unavailableIngredients = [];

    for (int i = 0; i < widget.recipe.ingredients.length; i++) {
      if (!_ingredientAvailability[i]) {
        try {
          final replacementIngredientName = await fetchReplacementIngredient(widget.recipe.ingredients[i].name);
          setState(() {
            _replacementIngredients[i] = replacementIngredientName;
            widget.recipe.ingredients[i].name = replacementIngredientName;
          });
        } catch (e) {
          
          unavailableIngredients.add(widget.recipe.ingredients[i]);
        }
      }
    }

    await Future.delayed(Duration(seconds: 5));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepByStepPage(recipe: widget.recipe, servingSize: widget.servingSize),
      ),
    );
  }

  void _goToShoppingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListPage(
          unavailableIngredients: widget.recipe.ingredients
              .where((ingredient) => !_ingredientAvailability[widget.recipe.ingredients.indexOf(ingredient)])
              .toList(),
        ),
      ),
    );
  }

  void _refreshIngredients() {
    setState(() {
      _ingredientAvailability = List.generate(widget.recipe.ingredients.length, (index) => false);
      _replacementIngredients = List.generate(widget.recipe.ingredients.length, (index) => '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.recipe.title} Ingredients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: _goToShoppingList,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshIngredients,
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Scrollbar(
        child: ListView.builder(
          itemCount: widget.recipe.ingredients.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text('${index + 1}.'),
              title: Text(widget.recipe.ingredients[index].name),
              subtitle: _replacementIngredients[index].isNotEmpty ? Text('Replacement: ${_replacementIngredients[index]}', style: TextStyle(color: Colors.red)) : null,
              onTap: () {
                setState(() {
                  _ingredientAvailability[index] = !_ingredientAvailability[index];
                });
              },
              trailing: Checkbox(
                value: _ingredientAvailability[index],
                onChanged: (bool? newValue) {
                  setState(() {
                    _ingredientAvailability[index] = newValue ?? false;
                  });
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleContinue,
        child: Icon(Icons.arrow_forward),

      ),
    );
  }
}
