import 'dart:async';

import 'package:flutter/material.dart';

class StepCard extends StatefulWidget {
  final String step;
  final int stepNumber;
  final bool isActive;

  const StepCard({
    Key? key,
    required this.step,
    required this.stepNumber,
    required this.isActive,
  }) : super(key: key);

  @override
  _StepCardState createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timerSeconds += 1;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isTimerRunning ? _stopTimer : _startTimer,
      child: Card(
        color: widget.isActive ? Colors.yellow[100] : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${widget.stepNumber}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_isTimerRunning)
                    Text(
                      '${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                widget.step,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
