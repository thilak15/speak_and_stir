import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speak_and_stir/models/recipe.dart';
import 'package:speak_and_stir/utils/speech_recognition.dart';
import 'package:speak_and_stir/utils/text_to_speech.dart';
import 'package:speak_and_stir/widgets/step_card.dart';

class StepByStepPage extends StatefulWidget {
  final Recipe recipe;
  final int servingSize;

  StepByStepPage({required this.recipe, required this.servingSize});

  @override
  _StepByStepPageState createState() => _StepByStepPageState();
}

class _StepByStepPageState extends State<StepByStepPage> {
  final TextToSpeech _textToSpeech = TextToSpeech();
  final SpeechRecognition _speechRecognition = SpeechRecognition();
  int _currentStep = 0;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isExecutingCommand = false;
  bool _hasStarted = false;


  ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _speechRecognition.initialize().then((_) {
    if (_speechRecognition.isAvailable) {
      _startListening();
    } else {
      print("Speech recognition not available");
    }
  });
}


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _startListening() async {
  if (!mounted) return;
  if (!_speechRecognition.isListening) {
    _speechRecognition.onListeningStopped = () {
      _startListening();
    };
    setState(() {
      _isListening = true;
    });
    await _speechRecognition.listen(
      onResult: (String result) async {
        if (_isExecutingCommand) return;
        _isExecutingCommand = true;
        String command = result.toLowerCase();
        if (command.contains("start") && !_hasStarted) {
          _hasStarted = true;
          _speakStep();
        } else if (command.contains("next step")) {
          _nextStep();
        } else if (command.contains("previous step")) {
          _previousStep();
        } else if (command.contains("repeat")) {
          _repeatStep();
        } else if (command.contains("scroll up")) {
          _scrollUp();
        } else if (command.contains("scroll down")) {
          _scrollDown();
        } else if (command.contains("start the timer")) {
          int minutes = 5;
          RegExp regExp = RegExp(r'\d+');
          Iterable<RegExpMatch> matches = regExp.allMatches(command);
          for (RegExpMatch match in matches) {
            minutes = int.parse(match.group(0) ?? '0');
            break;
          }
          _startTimer(minutes);
        }
        _isExecutingCommand = false;
      },
      onCancelled: () {
        _startListening();
      },
    );
  }
}



Future<void> _stopListening() async {
  await _speechRecognition.stop();
  setState(() {
    _isListening = false;
  });
}

      

Future<void> _speakStep() async {
  if (!_isSpeaking) {
    _isSpeaking = true;
    await _stopListening();
    await _textToSpeech.speak("Step ${_currentStep + 1}: ${widget.recipe.steps[_currentStep]}");
    await _textToSpeech.pauseFor(Duration(seconds: 4));
    _isSpeaking = false;
    _startListening();
  }
}


  void _nextStep() {
  if (_currentStep < widget.recipe.steps.length - 1) {
    setState(() {
      _currentStep = _currentStep + 1;
    });
    _speakStep();
  }
}



  void _previousStep() {
    setState(() {
      _currentStep = (_currentStep - 1 + widget.recipe.steps.length) % widget.recipe.steps.length;
    });
    _speakStep();
  }

  void _repeatStep() {
    _speakStep();
  }

    void _scrollUp() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }


  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _startTimer(int minutes) {
    if (minutes > 0) {
      _textToSpeech.speak("Starting timer for $minutes minutes.");
      Timer(Duration(minutes: minutes), () {
        _textToSpeech.speak("Timer finished. $minutes minutes have passed.");
      });
    } else {
      _textToSpeech.speak("Please specify the number of minutes for the timer.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: () {
              if (_isListening) {
                _speechRecognition.stop();
              } else {
                _startListening();
              }
              setState(() {
                _isListening = !_isListening;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            for (int i = 0; i < widget.recipe.steps.length; i++)
              InkWell(
                onTap: () {
                  setState(() {
                    _currentStep = i;
                  });
                  _speakStep();
                },
                child: StepCard(
                  stepNumber: i + 1,
                  step: widget.recipe.steps[i],
                  isActive: i == _currentStep,
                ),
              ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  ElevatedButton.icon(
                    onPressed: _previousStep,
                    icon: Icon(Icons.arrow_back),
                    label: Text("Previous Step"),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: Icon(Icons.arrow_forward),
                    label: Text("Next Step"),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _repeatStep,
                    icon: Icon(Icons.replay),
                    label: Text("Repeat Step"),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

