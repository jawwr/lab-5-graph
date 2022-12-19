import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lab_5/models/states.dart';

import '../service/graph_logic.dart';

class NodeWidget extends ImplicitlyAnimatedWidget {
  late final Function(dynamic)? callback;
  final Function(Node<num>, Point)? changeLoc;
  final Node<num> node;
  final Graph<num> graph;
  final Function(Node<num>, Node<num>) addEdge;
  Point location;

  NodeWidget(
    this.location, {
    Key? key,
    Duration swapAnimationDuration = const Duration(milliseconds: 150),
    Curve swapAnimationCurve = Curves.linear,
    required this.graph,
    required this.node,
    required this.addEdge,
    this.changeLoc,
    this.callback,
  }) : super(
            key: key,
            duration: swapAnimationDuration,
            curve: swapAnimationCurve);
  var stateNow = _NodeWidget();
  static final List<Node<num>> selectedNodes = [];

  @override
  _NodeWidget createState() => stateNow;
}

class _NodeWidget extends AnimatedWidgetBaseState<NodeWidget> {
  get state => _state;
  var _state = ObjectState.idle;

  _deleteNode(Node<num> node) => {
        setState(() {
          if (widget.callback != null) {
            widget.callback!.call(widget.node);
          }
          widget.graph.removeNode(node);
        })
      };

  changeState(ObjectState state) {
    setState(() {
      _state = state;
    });
  }

  _selectNode(Node<num> node) => {
        setState(() {
          if (_state == ObjectState.idle) {
            // if (NodeWidget.selectedNodes.isNotEmpty) {
            //   widget.addEdge.call(NodeWidget.selectedNodes.first, widget.node);
            //   NodeWidget.selectedNodes.clear();
            //   _state = ObjectState.idle;
            // } else {
              _state = ObjectState.select;
              NodeWidget.selectedNodes.add(node);
            // }
          } else {
            _state = ObjectState.idle;
            NodeWidget.selectedNodes.clear();
          }
        })
      };

  _moveNode(BuildContext context, DragUpdateDetails details) => setState(() {
        final Offset local = details.globalPosition;
        widget.location = Point(local.dx, local.dy);
        if (widget.changeLoc != null) {
          widget.changeLoc!.call(widget.node, Point(local.dx, local.dy));
        }
      });

  Color _getColor() {
    switch (_state) {
      case ObjectState.idle:
        return Colors.teal;
      case ObjectState.select:
        return Colors.pink;
      case ObjectState.passed:
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.location.y - 20,
      left: widget.location.x - 20,
      width: 40,
      height: 40,
      child: GestureDetector(
        onPanUpdate: (details) => _moveNode(context, details),
        onTap: () => _selectNode(widget.node),
        onDoubleTap: () => _deleteNode(widget.node),
        child: Container(
          child: Center(
              child: Text(
            "${widget.node.id}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              decoration: TextDecoration.none,
            ),
          )),
          decoration: BoxDecoration(
            color: _getColor(),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {}
}
