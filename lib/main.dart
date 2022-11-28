import 'package:flutter/material.dart';
import 'package:lab_5/widgets/graph.dart';
import 'package:toast/toast.dart';

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
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return GraphWidget();
  }
}