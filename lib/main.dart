import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CALX',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CalculatorHomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/logo.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage>
    with SingleTickerProviderStateMixin {
  String _output = "0";
  String _currentInput = "";
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showCalculationResult(String result) {
    setState(() {
      _output = result;
    });
  }

  void _buttonPressed(String value) {
    setState(() {
      if (value == "CE") {
        _output = "0";
        _currentInput = "";
      } else if (value == "=") {
        try {
          Parser p = Parser();
          Expression exp = p.parse(_currentInput.replaceAll('x', '*'));
          ContextModel cm = ContextModel();
          String result = exp.evaluate(EvaluationType.REAL, cm).toString();
          _showCalculationResult(result);
        } catch (e) {
          _showCalculationResult("Error");
        }
      } else {
        _currentInput += value;
        _output = _currentInput;
      }
    });
  }

  void _processVoiceCommand(String command) {
    setState(() {
      try {
        if (command.contains("differentiate")) {
          final exp = command.replaceAll("differentiate", "").trim();
          Parser p = Parser();
          Expression expression = p.parse(exp);
          String result = expression.derive("x").simplify().toString();
          _showCalculationResult(result);
        } else if (command.contains("integrate")) {
          _showCalculationResult("Integration is not supported yet.");
        } else if (command.contains("matrix")) {
          _showCalculationResult("Matrix operations require structured input.");
        } else {
          Parser p = Parser();
          Expression exp = p.parse(command.replaceAll('x', '*'));
          ContextModel cm = ContextModel();
          String result = exp.evaluate(EvaluationType.REAL, cm).toString();
          _showCalculationResult(result);
        }
      } catch (e) {
        _showCalculationResult("Error processing command.");
      }
    });
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (error) => setState(() => _isListening = false),
        onStatus: (status) => setState(() => _isListening = status == 'listening'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _currentInput = val.recognizedWords;
            _processVoiceCommand(_currentInput);
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + 0.1 * _animationController.value,
              child: Text(
                'CALX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.7 + 0.3 * _animationController.value),
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
            onPressed: _startListening,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _output,
                  key: ValueKey<String>(_output),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white),
          ..._buildButtonRows(),
        ],
      ),
    );
  }

  List<Widget> _buildButtonRows() {
    final buttonRows = [
      ["CE", "/", "x", "-"],
      ["7", "8", "9", "+"],
      ["4", "5", "6", "="],
      ["1", "2", "3", "0"],
    ];

    return buttonRows.map((row) => _buildButtonRow(row)).toList();
  }

  Widget _buildButtonRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((value) => _buildButton(value)).toList(),
    );
  }

  Widget _buildButton(String value) {
    final isOperator = ["/", "x", "-", "+", "="];
    final buttonColor = isOperator.contains(value) ? Colors.deepOrange : Colors.grey[800];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: buttonColor,
          borderRadius: BorderRadius.circular(15.0),
          child: InkWell(
            onTap: () => _buttonPressed(value),
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
