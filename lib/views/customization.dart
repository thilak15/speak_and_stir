import 'package:flutter/material.dart';
import 'package:speak_and_stir/models/recipe.dart';
import 'package:speak_and_stir/utils/speech_recognition.dart';
import 'package:speak_and_stir/utils/text_to_speech.dart';
import 'package:speak_and_stir/views/ingredients.dart';

class CustomizationPage extends StatefulWidget {
  final Recipe recipe;

  CustomizationPage({required this.recipe});

  @override
  _CustomizationPageState createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  final TextToSpeech _textToSpeech = TextToSpeech();
  final SpeechRecognition _speechRecognition = SpeechRecognition();
  int _servingSize = 2;
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
              "Please provide any customizations for ${widget.recipe.title}.");
          await _textToSpeech.pauseFor(Duration(seconds: 4)); // Use pauseFor from the TextToSpeech instance
          _hasSpoken = true;
        }
        _startListening();
      }
    });
  }

   void _startListening() async {
    if (!_continuousListening) return;
    _isListening = true;
    await _speechRecognition.listen(
      onResult: (String result) {
        if (result.toLowerCase().contains("serving size")) {
          int? newServingSize = int.tryParse(result.toLowerCase().replaceAll(RegExp(r'\D'), ''));
          if (newServingSize != null) {
            setState(() {
              _servingSize = newServingSize;
            });
            _textToSpeech.speak("Serving size updated to $_servingSize.");
          }
        } else if (result.toLowerCase() == "continue") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientsPage(recipe: widget.recipe, servingSize: _servingSize),
            ),
          );
        }
      },
      onCancelled: () {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }



    void _stopListening() async {
    await _speechRecognition.stop();
    setState(() {
      _isListening = false;
    });
  }

    void _updateServingSize(bool increase) {
    setState(() {
      if (increase) {
        _servingSize += 1;
      } else {
        if (_servingSize > 1) {
          _servingSize -= 1;
        }
      }
    });
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize ${widget.recipe.title}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serving Size: $_servingSize',
                  style: TextStyle(fontSize: 18),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _updateServingSize(false),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _updateServingSize(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientsPage(recipe: widget.recipe, servingSize: _servingSize),
            ),
          );
        },
        child: Icon(Icons.arrow_forward),
      ),
    );
  }
}