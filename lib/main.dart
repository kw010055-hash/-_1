import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // ضبط شريط الحالة العلوي ليتناسب مع التصميم الداكن
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Calculator',
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF17171C),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _equation = "0";
  String _result = "0";
  bool _isFinalResult = false;

  // منطق الضغط على الأزرار
  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _equation = "0";
        _result = "0";
        _isFinalResult = false;
      } else if (buttonText == "⌫") {
        if (_equation.length > 1) {
          _equation = _equation.substring(0, _equation.length - 1);
        } else {
          _equation = "0";
        }
        _calculateLiveResult();
      } else if (buttonText == "=") {
        _calculateLiveResult(isFinal: true);
        _isFinalResult = true;
      } else if (buttonText == "+/-") {
        _toggleSign();
      } else if (buttonText == "%") {
        _applyPercentage();
      } else if (["+", "-", "×", "÷"].contains(buttonText)) {
        _isFinalResult = false;
        String lastChar = _equation.substring(_equation.length - 1);
        if (["+", "-", "×", "÷"].contains(lastChar)) {
          _equation = _equation.substring(0, _equation.length - 1) + buttonText;
        } else {
          _equation += buttonText;
        }
      } else {
        // كتابة الأرقام والنقطة العشرية
        if (_isFinalResult) {
          _equation = buttonText == "." ? "0." : buttonText;
          _isFinalResult = false;
        } else {
          if (_equation == "0" && buttonText != ".") {
            _equation = buttonText;
          } else {
            // منع تكرار النقطة في نفس الرقم
            if (buttonText == ".") {
              List<String> parts = _equation.split(RegExp(r'[+\-×÷]'));
              if (parts.last.contains('.')) return;
            }
            _equation += buttonText;
          }
        }
        _calculateLiveResult();
      }
    });
  }

  void _toggleSign() {
    try {
      if (_equation == "0") return;
      if (_equation.startsWith("-")) {
        _equation = _equation.substring(1);
      } else {
        _equation = "-$_equation";
      }
      _calculateLiveResult();
    } catch (_) {}
  }

  void _applyPercentage() {
    try {
      double val = double.parse(_result);
      val = val / 100;
      _result = _formatNumber(val);
      _equation = _result;
    } catch (_) {}
  }

  // حساب النتيجة اللحظية
  void _calculateLiveResult({bool isFinal = false}) {
    try {
      String cleanExpr = _equation.replaceAll('×', '*').replaceAll('÷', '/');
      double eval = _evaluateExpression(cleanExpr);
      _result = _formatNumber(eval);
      if (isFinal) {
        _equation = _result;
      }
    } catch (_) {
      if (isFinal) {
        _result = "خطأ";
      }
    }
  }

  // محرك الحساب البسيط للعمليات الأساسية
  double _evaluateExpression(String expr) {
    List<String> tokens = [];
    String numberBuffer = "";

    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];
      if ("+-*/".contains(char)) {
        if (char == '-' && (i == 0 || "+-*/".contains(expr[i - 1]))) {
          numberBuffer += char;
        } else {
          if (numberBuffer.isNotEmpty) {
            tokens.add(numberBuffer);
            numberBuffer = "";
          }
          tokens.add(char);
        }
      } else {
        numberBuffer += char;
      }
    }
    if (numberBuffer.isNotEmpty) tokens.add(numberBuffer);

    // معالجة الضرب والقسمة أولاً (الأولوية الرياضية)
    List<String> pass1 = [];
    int i = 0;
    while (i < tokens.length) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        String op = tokens[i];
        double prev = double.parse(pass1.removeLast());
        double next = double.parse(tokens[i + 1]);
        double res = op == '*' ? prev * next : prev / next;
        pass1.add(res.toString());
        i += 2;
      } else {
        pass1.add(tokens[i]);
        i++;
      }
    }

    // معالجة الجمع والطرح
    double total = double.parse(pass1[0]);
    for (int j = 1; j < pass1.length; j += 2) {
      String op = pass1[j];
      double next = double.parse(pass1[j + 1]);
      if (op == '+') total += next;
      if (op == '-') total -= next;
    }

    return total;
  }

  String _formatNumber(double value) {
    if (value.isInfinite || value.isNaN) return "خطأ";
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(4).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // شاشة عرض النتائج
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // نص المعادلة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _equation,
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // نص النتيجة النهائية
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _result,
                        style: const TextStyle(
                          fontSize: 54,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // لوحة الأزرار
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF21222A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButtonRow(["AC", "+/-", "%", "÷"]),
                    _buildButtonRow(["7", "8", "9", "×"]),
                    _buildButtonRow(["4", "5", "6", "-"]),
                    _buildButtonRow(["1", "2", "3", "+"]),
                    _buildButtonRow([".", "0", "⌫", "="]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء صف أزرار
  Widget _buildButtonRow(List<String> texts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: texts.map((text) => _buildButton(text)).toList(),
    );
  }

  // تصميم الزر الاحترافي
  Widget _buildButton(String text) {
    Color btnColor;
    Color textColor;

    // تخصيص الألوان حسب وظيفة الزر
    if (text == "AC") {
      btnColor = const Color(0xFF2C2D38);
      textColor = const Color(0xFFFF5252); // أحمر للأمر Clear
    } else if (["÷", "×", "-", "+", "="].contains(text)) {
      btnColor = const Color(0xFF4B7BFF); // أزرق عصري ومضيء للعمليات
      textColor = Colors.white;
    } else if (["+/-", "%", "⌫"].contains(text)) {
      btnColor = const Color(0xFF2C2D38);
      textColor = const Color(0xFF00E676); // أخضر نيون للوظائف الخاصة
    } else {
      btnColor = const Color(0xFF2A2B36); // رمادي غامق للأرقام
      textColor = Colors.white;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onButtonPressed(text),
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Ink(
              height: 68,
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 26,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
