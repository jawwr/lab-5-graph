import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 5',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstTaskGraph(),
    );
  }
}

class FirstTaskGraph extends StatefulWidget {
  const FirstTaskGraph({Key? key}) : super(key: key);

  @override
  State<FirstTaskGraph> createState() => _FirstTaskGraphState();
}

class _FirstTaskGraphState extends State<FirstTaskGraph> {
  static late List<Widget> drawElements;
  static late List<DrawElement> allElements;

  static void refresh() {
    for (var elem in allElements) {
      if (elem is Connection) {
        elem.line = LinesPainter(
            start: Offset(elem.point1.x, elem.point1.y),
            end: Offset(elem.point2.x, elem.point2.y));
      }
    }
    _refreshDrawList();
  }

  static void _refreshDrawList() {
    drawElements = drawElements.where((element) => element is Vertex).toList();
    for (var element in allElements) {
      if (element is Connection) {
        drawElements.add(
          CustomPaint(
            size: Size.infinite,
            painter: element.line,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    allElements = [
      Connection(
        Vertex(
          x: 300 - 50,
          y: 300 - 50,
          name: '23',
        ),
        Vertex(
          x: 200 - 20,
          y: 200 - 20,
          name: '89',
        ),
      )
    ];
    drawElements = [
      Vertex(
        x: 20,
        y: 20,
        name: '23',
      ),
      Vertex(
        x: 160,
        y: 120,
        name: '54',
      ),
      Vertex(
        x: 300 - 50,
        y: 300 - 50,
        name: '23',
      ),
      Vertex(
        x: 200 - 20,
        y: 200 - 20,
        name: '89',
      ),
    ];
    // _refreshDrawList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          double x = Random().nextDouble() * 1000;
          double y = Random().nextDouble() * 1000;
          String name = String.fromCharCode(Random().nextInt(60) + 30);
          setState(() {
            drawElements.add(Vertex(x: x, y: y, name: name));
          });
        },
        backgroundColor: Colors.teal,
        child: const Text(
          '+',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Stack(
            children: drawElements,
          ),
        ),
      ),
    );
  }
}

class LinesPainter extends CustomPainter {
  final Offset start, end;

  LinesPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = 4
          ..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(LinesPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}

class Connection implements DrawElement {
  Vertex point1;
  Vertex point2;
  LinesPainter? line;

  Connection(this.point1, this.point2) {
    line = LinesPainter(
        start: Offset(point1.x + 30, point1.y + 30),
        end: Offset(point2.x + 20, point2.y + 20));
  }
}

class Vertex extends StatefulWidget implements DrawElement {
  Vertex({Key? key, required this.x, required this.y, required this.name})
      : super(key: key);

  late double x;
  late double y;
  late String name;

  @override
  State<Vertex> createState() => _VertexState(x, y, name);
}

class _VertexState extends State<Vertex> {
  double x;
  double y;
  final String _name;
  final double _diametr = 50;

  late double dx;
  late double dy;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanStart: (details) {
          dx = x;
          dy = y;
          setState(() {
            x = details.localPosition.dx + dx - 20;
            y = details.localPosition.dy + dy - 20;

            widget.x = x;
            widget.y = y;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            x = details.localPosition.dx + dx - 20;
            y = details.localPosition.dy + dy - 20;

            widget.x = x;
            widget.y = y;
          });
          // _FirstTaskGraphState.refresh();
        },
        child: Container(
          width: _diametr,
          height: _diametr,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.all(
              Radius.circular(_diametr / 2),
            ),
          ),
          child: Center(
            child: Text(
              _name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    );
  }

  _VertexState(this.x, this.y, this._name);
}

class DrawElement {}
