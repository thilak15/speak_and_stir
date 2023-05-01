import 'package:flutter/material.dart';
import 'package:speak_and_stir/models/recipe.dart';
import 'package:speak_and_stir/utils/speech_recognition.dart';
import 'package:speak_and_stir/utils/text_to_speech.dart';
import 'package:speak_and_stir/widgets/recipe_card.dart';
import 'package:speak_and_stir/views/recipe_detail.dart';
import 'package:speak_and_stir/views/customization.dart';

class RecipeSelectionPage extends StatefulWidget {
  final List<Recipe> recipes;

  RecipeSelectionPage({required this.recipes});

  @override
  _RecipeSelectionPageState createState() => _RecipeSelectionPageState();
}



class _RecipeSelectionPageState extends State<RecipeSelectionPage> {
  final TextToSpeech _textToSpeech = TextToSpeech();
  final SpeechRecognition _speechRecognition = SpeechRecognition();
  ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _continuousListening = true;
  bool _hasSpoken = false; 

   @override
  void initState() {
    super.initState();
    _speechRecognition.initialize().then((value) async { 
      if (value) {
        if (!_hasSpoken) {
          await _textToSpeech.speak(
              "Here are the suggested recipes based on your input. Select the recipe by saying its number");
          await _textToSpeech.pauseFor(Duration(seconds: 5)); 
          _hasSpoken = true;
        }
         await _textToSpeech.pauseFor(Duration(seconds: 2));
        _startListening();
      }
    });
    
  }


 void _startListening() async {
  if (!_continuousListening) return;
  _isListening = true;
  
  await _speechRecognition.listen(
    onResult: (String result) {
      _handleResult(result);
    },
    onCancelled: () {
      _startListening();
    },
  );
  
  setState(() {});
}

void _handleResult(String result) {
  if (result.contains(RegExp(r'select the recipe \d+'))) {
    final number = int.tryParse(result.split(' ').last);
    print(number);
    if (number != null) {
      int recipeNumber = number;
      if (recipeNumber > 0 && recipeNumber <= widget.recipes.length) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetail(recipe: widget.recipes[recipeNumber - 1]),
          ),
        );
      }
    }
  } else if (result.contains('scroll up')) {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 500),
    );
  } else if (result.contains('scroll down')) {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 500),
    );
  }
}


  void _stopListening() async {
    await _speechRecognition.stop();
    setState(() {
      _isListening = false;
    });
  }
  @override
void dispose() {
  

  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange, // Update the AppBar color
        title: Text('Recipe Selection'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade200, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.recipes.length,
            itemBuilder: (context, index) {
              return Padding(
                                padding: EdgeInsets.all(8.0), 
                child: RecipeCard(
                  recipe: widget.recipes[index],
                  displayIndex: index + 1,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomizationPage(recipe: widget.recipes[index]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

