import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lab_5/DTO/graph_dto.dart';
import 'package:lab_5/service/converter.dart';
import 'package:lab_5/widgets/subtitle.dart';
import 'package:toast/toast.dart';

import '../models/node.dart';
import '../models/states.dart';
import '../service/graph_logic.dart';
import 'edge.dart';
import 'menu.dart';

class GraphWidget extends StatefulWidget {
  const GraphWidget({Key? key}) : super(key: key);

  @override
  State<GraphWidget> createState() => _GraphWidget();
}

class _GraphWidget extends State<GraphWidget> {
  var graph = Graph<num>.def(false);
  double posx = 0;
  double posy = 0;
  String _subtitles = "";
  final List<NodeWidget> _nodes = [];
  List<DistanceLineWidget> _edges = [];
  bool _isRun = false;
  bool _needSubtitles = false;
  Map<Node<num>, Point> map = {};

  _onTapDown(BuildContext context, TapDownDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset localOffset = box!.globalToLocal(details.globalPosition);
    var node = Node<num>(graph.lenght);
    posx = localOffset.dx;
    posy = localOffset.dy;
    var point = Point(posx, posy);
    setState(() {
      map[node] = point;
      graph.addNode(node);
      _nodes.add(NodeWidget(
        map[node]!,
        node: node,
        graph: graph,
        addEdge: _addEdge,
        callback: callback,
        changeLoc: _changeLoc,
      ));
    });
  }

  callback(changeObj) {
    setState(() {
      if (changeObj is Node<num>) {
        _edges = _edges
            .where((x) => !changeObj.incidentEdges.contains(x.edge))
            .toList();
        _nodes.remove(_nodes.where((widget) => widget.node == changeObj).first);
        map.remove(changeObj);
      } else if (changeObj is Edge<num>) {
        _edges.remove(_edges.where((widget) => widget.edge == changeObj).first);
      } else {
        deactivate();
      }
    });
  }

  _changeLoc(Node<num> node, loc) {
    map[node] = loc;
    setState(() {
      _edges = _edges
          .where((x) => x.edge.to != node && x.edge.from != node)
          .toList();

      for (var edge in node.incidentEdges) {
        _edges.insert(
            0,
            DistanceLineWidget(
                edge: edge,
                graph: graph,
                callback: callback,
                to: map[edge.to]!,
                from: map[edge.from]!));
      }
    });
  }

  _showAlertDialog(String text) {
    Toast.show(
      text,
      duration: Toast.lengthShort,
      gravity: Toast.bottom,
      backgroundColor: Colors.grey,
      webTexColor: Colors.white,
      backgroundRadius: 50,
    );
  }

  _openSubtitles() {
    _showAlertDialog("Subtitles are turn on");
    setState(() {
      _needSubtitles = !_needSubtitles;
    });
  }

  _saveFile() async {
    var dto = convertGraphToDTO(graph, map);
    var json = graphDTOToJson(dto);
    Uint8List uint8list = Uint8List.fromList(json.codeUnits);
    await FileSaver.instance.saveFile("graph.json", uint8list, "json");
  }

  _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (kIsWeb) {
      if (result != null) {
        var isJson = result.files[0].name.contains(".json");
        Tuple<Graph<num>, Map<Node<num>, Point>> tuple;
        var fileBytes = result.files.first.bytes;
        var text = utf8.decode(fileBytes!);
        if (isJson) {
          var graphDto = graphDTOFromJson(text);
          tuple = text.convertDtoToGraph(graphDto, false);
        } else {
          tuple = text.convertToGraph(false);
        }
        setState(() {
          _nodes.clear();
          _edges.clear();
          graph = tuple.item1;
          map = tuple.item2;
          for (var node in graph.nodes) {
            _nodes.add(NodeWidget(
              map[node]!,
              graph: graph,
              node: node,
              addEdge: _addEdge,
              changeLoc: _changeLoc,
            ));
          }
          for (var edge in graph.edges) {
            _edges.add(DistanceLineWidget(
                edge: edge,
                graph: graph,
                to: map[edge.to]!,
                from: map[edge.from]!));
          }
        });
      }
    }
  }

  _graphBypass(Function(Node<num>) action) {
    if (_nodes.any((node) => node.stateNow.state == ObjectState.select) &&
        !_isRun) {
      var node = _nodes
          .where((node) => node.stateNow.state == ObjectState.select)
          .first
          .node;
      action.call(node);
      NodeWidget.selectedNodes.clear();
    } else {
      _showAlertDialog("Warning: You don't select node.");
    }
  }

  String _toString(Iterable nodes) {
    var text = "";
    for (var node in nodes.map((x) => x.id.toString())) {
      text += " $node";
    }
    return text;
  }

  _changeNodeState(node, ObjectState state) {
    setState(() {
      _nodes
          .where((node2) => node2.node.id == node.id)
          .first
          .stateNow
          .changeState(state);
    });
  }

  _printSubs(text) {
    setState(() {
      _subtitles = text;
    });
  }

  _changeToken(isStart) {
    setState(() {
      _isRun = isStart;
    });
  }

  _changeAllNode(ObjectState state) {
    setState(() {
      for (var node in _nodes) {
        node.stateNow.changeState(state);
      }
    });
  }

  _depthSearch(Node<num> startNode) async {
    List<Node<num>> path = [];
    _changeToken(true);
    var visited = HashSet<Node<num>>();
    ListQueue<Node<num>> stack = ListQueue();
    stack.addLast(startNode);
    while (stack.isNotEmpty) {
      var node = stack.removeLast();
      if (!visited.contains(node)) {
        visited.add(node);
        _changeNodeState(node, ObjectState.passed);
        _printSubs("Visiting node number ${node.id}");
        path.add(node);
        await Future.delayed(const Duration(milliseconds: 500));
        _changeNodeState(node, ObjectState.passed);
        await Future.delayed(const Duration(milliseconds: 1000));
        for (var incidentNode in node.incidentNodes) {
          stack.addLast(incidentNode);
        }
        _printSubs("Stack have ${_toString(stack)}");
        await Future.delayed(const Duration(milliseconds: 750));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _printSubs("finally path ${_toString(path)}");
    await Future.delayed(const Duration(milliseconds: 1000));
    _printSubs("");
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
  }

  _breadthSearch(Node<num> startNode) async {
    List<Node<num>> path = [];
    setState(() {
      _isRun = true;
    });
    var visited = HashSet<Node<num>>();
    var queue = Queue<Node<num>>();
    queue.add(startNode);
    while (queue.isNotEmpty) {
      var node = queue.removeFirst();
      if (!visited.contains(node)) {
        visited.add(node);
        _changeNodeState(node, ObjectState.passed);
        _printSubs("Visiting node number ${node.id}");
        path.add(node);
        await Future.delayed(const Duration(milliseconds: 500));
        _changeNodeState(node, ObjectState.passed);
        await Future.delayed(const Duration(milliseconds: 1000));
        for (var incidentNode in node.incidentNodes) {
          queue.add(incidentNode);
        }
        _printSubs("Queue have ${_toString(queue)}");
        await Future.delayed(const Duration(milliseconds: 750));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _printSubs("finally path ${_toString(path)}");
    await Future.delayed(const Duration(milliseconds: 1000));
    _printSubs("");
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
  }

  _calculateMinWay(Node<num> startNode, Node<num> endNode) async {
    List<List<int>> path = [];
    List<List<int>> graphDest = _getEdges();
    setState(() {
      _isRun = true;
    });
    var size = graph.lenght;
    for (int k = 0; k < size; k++) {
      for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
          if (graphDest[i][k] != _maxInt &&
              graphDest[k][j] != _maxInt &&
              graphDest[i][j] > graphDest[i][k] + graphDest[k][j]) {
            graphDest[i][j] = graphDest[i][k] + graphDest[k][j];
          }
        }
      }
    }
  }

  List<List<int>> _getEdges() {
    List<List<int>> graphEdges = [];
    for (int i = 0; i < graph.lenght; i++) {
      var nodes = graph.nodes.toList()[i].incidentEdges.toList();
      List<int> list = [];
      graphEdges.add(list);

      for (int j = 0; j < graph.lenght; j++) {
        if (nodes[0].from.id == j) {
          graphEdges[i].add(0);
          continue;
        }
        var isContains = false;
        for (var edge in nodes) {
          if (edge.to.id == j) {
            isContains = true;
            break;
          }
        }
        if (isContains) {
          graphEdges[i].add(
              nodes.where((element) => element.to.id == j).first.value as int);
        } else {
          graphEdges[i].add(_maxInt);
        }
      }
    }

    return graphEdges;
  }

  Future<int> _showDialog() async {
    dynamic resultValue = -1;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Input value of distance'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Enter num',
                  ),
                  onChanged: (value) {
                    try {
                      resultValue = _validateValue(value);
                    } catch (e) {
                      resultValue = -1;
                    }
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(-1);
              },
            ),
            ElevatedButton(
              child: Text('Ok'),
              onPressed: () {
                if (resultValue != -1) {
                  Navigator.of(context).pop(resultValue);
                }
              },
            ),
          ],
        );
      },
    );
    return resultValue;
  }

  _addEdge(Node<num> node1, Node<num> node2) async {
    if (graph.isOriented
        ? !graph.edges.any((node) => node.from == node1 && node.to == node2)
        : !graph.edges.any((node) =>
            (node.from == node1 || node.from == node2) &&
            (node.to == node2 || node.to == node1))) {
      final int value = await _showDialog().then((value) => value) as int;
      if (value == -1 || value == null) {
        for (var node in _nodes) {
          node.stateNow.changeState(ObjectState.idle);
        }
        return;
      }

      setState(() {
        for (var node in _nodes) {
          node.stateNow.changeState(ObjectState.idle);
        }
        var edge = graph.connect(node1, node2, value);
        _edges.add(DistanceLineWidget(
            edge: edge,
            graph: graph,
            callback: callback,
            to: map[edge.to]!,
            from: map[edge.from]!));
      });
    } else {
      _showAlertDialog("this is edge is exist, please delete and make new");
      setState(() {
        for (var node in _nodes) {
          node.stateNow.changeState(ObjectState.idle);
        }
        callback(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _needSubtitles
            ? Subtitles(text: _subtitles)
            : const Text(
                "",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
        GestureDetector(
          onTapDown: (TapDownDetails details) => _onTapDown(context, details),
        ),
        ..._nodes,
        ..._edges,
        Positioned(
          bottom: 50,
          right: 50,
          child: Menu(
            depthSearch: () => _graphBypass(_depthSearch),
            breadthSearch: () => _graphBypass(_breadthSearch),
            openSubtitles: () => _openSubtitles(),
            saveFile: () => _saveFile(),
            uploadFile: () => _uploadFile(),
            minWay: () => _calculateMinWay(Node(1), Node(2)),
          ),
        ),
      ],
    );
  }

  int _validateValue(String value) {
    if (value == null) {
      throw NullThrownError();
    }
    if (value.isEmpty) {
      throw ArgumentError();
    }
    if (int.tryParse(value) == null) {
      throw ArgumentError();
    }
    if (int.parse(value) <= 0) {
      throw ArgumentError();
    }
    return int.parse(value);
  }
}

const int _maxInt = 999999;