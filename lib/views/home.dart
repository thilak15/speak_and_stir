import 'dart:core';
import 'package:flutter/material.dart';
import 'package:speak_and_stir/utils/speech_recognition.dart';
import 'package:speak_and_stir/utils/text_to_speech.dart';
import 'package:speak_and_stir/views/recipe_selection.dart';
import 'package:speak_and_stir/utils/gpt_nlp.dart';
import 'package:speak_and_stir/views/shopping_list.dart'; 


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextToSpeech _textToSpeech = TextToSpeech();
  final SpeechRecognition _speechRecognition = SpeechRecognition();
  final GPTNLP _gptNLP = GPTNLP();

  bool _isListening = false;
  bool _wakeUpWordDetected = false;
  bool _isProcessing = false;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();

    _speechRecognition.initialize().then((value) {
      if (value) {
        _textToSpeech.speak("Welcome to Speak and Stir! Say 'Let's Cook' to get started.");
        _startListening();
      }
    });
  }


  void _startListening() {
    if (!_speechRecognition.isListening) {
      _speechRecognition.onListeningStopped = () {
        _startListening();
      };
      _speechRecognition.listen(
        onResult: (String result) {
          if (_isProcessing) return;

          print(result);
          setState(() {
            if (!_wakeUpWordDetected && result.contains("Let's cook")) {
              _wakeUpWordDetected = true;
              _textToSpeech.speak("Hey,What do you want to cook today?");
            } else if (_wakeUpWordDetected) {
              RegExp searchPattern = RegExp(r'I want to make (\w+)');
              Match? match = searchPattern.firstMatch(result);
              if (match != null && match.groupCount >= 1) {
                String searchTerm = match.group(1)!;
                print("Search term: $searchTerm");
                _isProcessing = true;
                _textToSpeech.speak("finding recipes including $searchTerm.");

                _gptNLP.generateRecipes(searchTerm ,count: 2).then((generatedRecipes) {
                  _isProcessing = false;

                  if (generatedRecipes.isNotEmpty) {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeSelectionPage(recipes: generatedRecipes),
                      ),
                    );
                  } else {
                    _textToSpeech.speak("Sorry did not find any recipe including $searchTerm.");
                  }
                });
              }
            }
          });
        },
        onCancelled: () {
          _startListening();
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechRecognition.stop();
    setState(() {
      _isListening = false;
    });
  }
Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Shopping List'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingListPage(
                    unavailableIngredients: [], 
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speak and Stir'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 100, height: 100),
                SizedBox(height: 20),
                Text(
                  "Welcome to Speak and Stir!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  "Activate the app by saying:",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  "\"Let's cook\"",
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _startListening();
                  },
                  child: Text("Let's Cook"),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.orange.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                _isProcessing
                    ? CircularProgressIndicator()
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
