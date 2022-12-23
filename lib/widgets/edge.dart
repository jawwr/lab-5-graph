import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lab_5/service/drawer.dart';

import '../service/graph_logic.dart';

class DistanceLineWidget extends StatefulWidget {
  final Function(dynamic)? callback;
  Edge<num> edge;
  Graph<num> graph;
  Point to;
  Point from;

  DistanceLineWidget({
    Key? key,
    required this.edge,
    required this.graph,
    this.callback,
    required this.to,
    required this.from,
  }) : super(key: key);

  @override
  State<DistanceLineWidget> createState() => _EdgeWidget();
}

class _EdgeWidget extends State<DistanceLineWidget> {
  _deleteEdge() {
    setState(() {
      widget.graph.disconect(widget.edge);
      if (widget.callback != null) {
        widget.callback!.call(widget.edge);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 20,
      height: 20,
      top: (widget.to.y + (widget.from.y - widget.to.y) / 2) - 20,
      left: widget.to.x + (widget.from.x - widget.to.x) / 2 - 20,
      child: Stack(
        children: [
          CustomPaint(
            painter: DrawHorizontalLine(
              Point(-(widget.from.x - widget.to.x) / 2 + 20,
                  -(widget.from.y - widget.to.y) / 2 + 20),
              Point((widget.from.x - widget.to.x) / 2 + 20,
                  (widget.from.y - widget.to.y) / 2 + 20),
            ),
          ),
          GestureDetector(
            onDoubleTap: _deleteEdge,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.edge.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
