import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  final Function(double) onValueSelected;

  CalculatorPage({required this.onValueSelected});

  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '';
  List<String> historyList = [];
  double currentTotal = 0.0;
  String operation = '';
  bool shouldCalculate = false;
  String currentEquation = '';
  final ScrollController _scrollController = ScrollController();

  void onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        display = '';
        historyList.clear();
        currentEquation = '';
        currentTotal = 0.0;
        operation = '';
        shouldCalculate = false;
      } else if (buttonText == 'DEL') {
        display =
            display.isNotEmpty ? display.substring(0, display.length - 1) : '';
      } else if (buttonText == '=') {
        if (display.isNotEmpty) {
          _calculateResult();
          currentEquation += '$display = ${currentTotal.toStringAsFixed(2)}';
          historyList.add(currentEquation);
          currentEquation = currentTotal.toStringAsFixed(2);
          display = (currentTotal % 1 == 0)
              ? currentTotal.toStringAsFixed(0)
              : currentTotal.toStringAsFixed(2);
          operation = '';
          shouldCalculate = false;
        }
      } else if (['+', '-', '×', '÷'].contains(buttonText)) {
        if (display.isNotEmpty) {
          if (shouldCalculate) {
            _calculateResult();
          } else {
            currentTotal = double.tryParse(display) ?? 0.0;
          }
          if (!currentEquation.contains(display)) {
            currentEquation += '$display $buttonText ';
            historyList
                .add(currentEquation);
          } else {
            currentEquation =
                '${currentEquation.substring(0, currentEquation.length - 2)}$buttonText ';
            historyList[historyList.length - 1] =
                currentEquation;
          }
          display = '';
          operation = buttonText;
          shouldCalculate = true;
        } else if (shouldCalculate) {
          operation = buttonText;
          currentEquation =
              '${currentEquation.substring(0, currentEquation.length - 2)}$buttonText ';
          historyList[historyList.length - 1] =
              currentEquation;
        }
      } else {
        if (buttonText == '.' && display.contains('.')) return;
        display += buttonText;
      }
    });
  }

  void _calculateResult() {
    double secondNumber = double.tryParse(display) ?? 0.0;

    switch (operation) {
      case '+':
        currentTotal += secondNumber;
        break;
      case '-':
        currentTotal -= secondNumber;
        break;
      case '×':
        currentTotal *= secondNumber;
        break;
      case '÷':
        if (secondNumber != 0) {
          currentTotal /= secondNumber;
        }
        break;
      default:
        break;
    }

    operation = '';
    shouldCalculate = false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      backgroundColor: Colors.tealAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      title: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Simple Calculator',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.08,
              ),
            ),
          ),
          Divider(color: Colors.grey),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    return Text(
                      historyList[historyList.length - index - 1],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: size.width * 0.05,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      display.isEmpty
                          ? (currentTotal % 1 == 0
                              ? currentTotal.toStringAsFixed(0)
                              : currentTotal.toString())
                          : display,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: size.width * 0.15,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.backspace_outlined, color: Colors.red),
                    onPressed: () => onButtonPressed('DEL'),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                crossAxisSpacing: size.width * 0.02,
                mainAxisSpacing: size.height * 0.02,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  calcButton('7', Colors.blueGrey, size),
                  calcButton('8', Colors.blueGrey, size),
                  calcButton('9', Colors.blueGrey, size),
                  calcButton('C', Colors.red, size),
                  calcButton('4', Colors.blueGrey, size),
                  calcButton('5', Colors.blueGrey, size),
                  calcButton('6', Colors.blueGrey, size),
                  SizedBox(
                    height: size.height * 0.1,
                    child: ElevatedButton(
                      onPressed: () => onButtonPressed('×'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        operation == '*' ? Colors.green : Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(size.width * 0.03),
                      ),
                      child: Text(
                        '×',
                        style: TextStyle(
                          fontSize: size.width * 0.12,
                          color: Colors.white,
                          height: 0.1,
                        ),
                      ),
                    ),
                  ),
                  calcButton('1', Colors.blueGrey, size),
                  calcButton('2', Colors.blueGrey, size),
                  calcButton('3', Colors.blueGrey, size),
                  SizedBox(
                    height: size.height * 0.1,
                    child: ElevatedButton(
                      onPressed: () => onButtonPressed('-'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        operation == '-' ? Colors.green : Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(size.width * 0.03),
                      ),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: size.width * 0.18,
                          color: Colors.white,
                          height: 0.1,
                        ),
                      ),
                    ),
                  ),
                  calcButton('.', Colors.blueGrey, size),
                  calcButton('0', Colors.blueGrey, size),

                  SizedBox(
                    height: size.height * 0.1,
                    child: ElevatedButton(
                      onPressed: () => onButtonPressed('÷'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        operation == '/' ? Colors.green : Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(size.width * 0.03),
                      ),
                      child: Text(
                        '÷',
                        style: TextStyle(
                          fontSize: size.width * 0.12,
                          color: Colors.white,
                          height: 0.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.1,
                    child: ElevatedButton(
                      onPressed: () => onButtonPressed('+'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: operation == '+'
                            ? Colors.green
                            : Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(size.width * 0.03),
                      ),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: size.width * 0.12,
                          color: Colors.white,
                          height: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      height: size.height * 0.08,
                      child: ElevatedButton(
                        onPressed: () {
                          if (display.isNotEmpty) {
                            if (shouldCalculate) {
                              _calculateResult();
                            } else {
                              currentTotal = double.tryParse(display) ?? 0.0;
                            }
                            widget.onValueSelected(double.parse(currentTotal.toStringAsFixed(2)));
                          } else {
                            widget.onValueSelected(double.parse(currentTotal.toStringAsFixed(2)));
                          }
                          operation = '';
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.02),
                  SizedBox(
                    width: size.width * 0.2,
                    height: size.height * 0.08,
                    child: ElevatedButton(
                      onPressed: () => onButtonPressed('='),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.02),
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: size.width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget calcButton(String text, Color color, Size size) {
    return ElevatedButton(
      onPressed: () => onButtonPressed(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(size.width * 0.03),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size.width * 0.07,
          color: Colors.white,
        ),
      ),
    );
  }
}
