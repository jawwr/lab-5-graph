import 'dart:collection';
import 'dart:convert';
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
import 'package:flutter/rendering.dart';
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
  final List<NodeWidget> _additionalNodes = [];
  List<DistanceLineWidget> _edges = [];
  bool _isRun = false;
  bool _needSubtitles = false;
  Map<Node<num>, Point> map = {};
  List<String> _logList = [];

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
    _showAlertDialog("???????????????? ????????????????");
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
      _showAlertDialog("Warning: ???? ?????????????? ??????????");
    }
  }

  String _toString(Iterable nodes) {
    var text = "";
    for (var node in nodes.map((x) => x.id.toString())) {
      text += " $node";
    }
    return text;
  }

  _changeNodeState(Node node, ObjectState state) {
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
      if (text != "") {
        _logList.add("${_logList.length + 1}) $text");
      }
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

  _clearLogs() {
    setState(() {
      _logList.clear();
    });
  }

  _depthSearch(Node<num> startNode) async {
    _clearLogs();
    List<Node<num>> path = [];
    _changeToken(true);
    var visited = HashSet<Node<num>>();
    ListQueue<Node<num>> stack = ListQueue();
    stack.addLast(startNode);
    while (stack.isNotEmpty) {
      var node = stack.removeLast();
      _printSubs("???? ?????????? ??????????????: ${_toString(stack)}");
      await Future.delayed(const Duration(milliseconds: 500));
      if (!visited.contains(node)) {
        visited.add(node);
        _changeNodeState(node, ObjectState.passed);
        _printSubs("???????? ?????????? ${node.id}");
        path.add(node);
        _printSubs("???????????????? ????????: ${_toString(path)}");
        await Future.delayed(const Duration(milliseconds: 500));
        _changeNodeState(node, ObjectState.passed);
        await Future.delayed(const Duration(milliseconds: 1000));
        for (var incidentNode in node.incidentNodes) {
          stack.addLast(incidentNode);
        }
        _printSubs("?? ??????????: ${_toString(stack)}");
        await Future.delayed(const Duration(milliseconds: 750));
      } else {
        _printSubs("");
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _printSubs("???????????????? ????????: ${_toString(path)}");
    await Future.delayed(const Duration(milliseconds: 1500));
    _printSubs("");
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
  }

  _breadthSearch(Node<num> startNode) async {
    _clearLogs();
    List<Node<num>> path = [];
    _changeToken(true);
    var visited = HashSet<Node<num>>();
    var queue = Queue<Node<num>>();
    queue.add(startNode);
    while (queue.isNotEmpty) {
      var node = queue.removeFirst();
      _printSubs(
          "???? ?????????????? ??????????????: ${node.id} ?? ??????????????: ${_toString(queue)}");
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!visited.contains(node)) {
        visited.add(node);
        _changeNodeState(node, ObjectState.passed);
        _printSubs("???????? ?????????? ${node.id}");
        path.add(node);
        _printSubs("???????????????? ????????: ${_toString(path)}");
        await Future.delayed(const Duration(milliseconds: 500));
        _changeNodeState(node, ObjectState.passed);
        await Future.delayed(const Duration(milliseconds: 1000));
        for (var incidentNode in node.incidentNodes) {
          queue.add(incidentNode);
        }
        _printSubs("?? ??????????????: ${_toString(queue)}");
        await Future.delayed(const Duration(milliseconds: 750));
      } else {
        _printSubs("");
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _printSubs("???????????????? ???????? ${_toString(path)}");
    await Future.delayed(const Duration(milliseconds: 1500));
    _printSubs("");
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
  }

  _calculateMinWay(Node<num> startNode, Node<num> endNode) async {
    List<int> path = [];
    List<List<int>> graphDest = _getEdges();
    if (graphDest[startNode.id][endNode.id] != _maxInt) {
      path.add(startNode.id);
      path.add(endNode.id);
    }
    _changeToken(true);
    var size = graph.lenght;
    for (int k = 0; k < size; k++) {
      var temp = List.of(graphDest);
      for (int i = 0; i < size; i++) {
        var node1 = graph[i];
        _changeNodeState(node1, ObjectState.select);
        _printSubs("???????????????? ?????????? ???? ?????????? ${node1.id}");

        for (int j = 0; j < size; j++) {
          var temp = graphDest[i][j];
          var node2 = graph[j];
          if (i != j) {
            _changeNodeState(node2, ObjectState.passed);

            _printSubs(
                "???????? ???? ${node1.id} ?? ${node2.id} ?????????? ${graphDest[i][j]}");
          }
          if (graphDest[i][k] != _maxInt &&
              graphDest[k][j] != _maxInt &&
              graphDest[i][j] > graphDest[i][k] + graphDest[k][j]) {
            graphDest[i][j] = graphDest[i][k] + graphDest[k][j];

            if (j == endNode.id) {
              temp = min(temp, graphDest[i][j]);
            }

            if (i == startNode.id && j == endNode.id) {
              path.remove(j);

              path.add(i);
              path.add(k);
              path.add(j);
            }
            _printSubs(
                "???????? ???? ${i} ?? ${j}, ???????????? ${graphDest[i][j]}, ???????????? ?????? ?????????? $i $k $j");
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (i != j) {
            _changeNodeState(node2, ObjectState.idle);
          }
        }
        _changeNodeState(node1, ObjectState.idle);
      }
      if (temp == graphDest) {
        break;
      }
    }

    var pathStr = "";
    for (var nodePath in path) {
      var node = graph[nodePath];
      _changeNodeState(node, ObjectState.select);
      _printSubs("???????????????????? ???????? ?????????? ?????????? ?????????? ${node.id}");
      pathStr += nodePath == path.first ? "$nodePath" : " -> $nodePath";
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _printSubs(
        "???????????????????? ???????? ${pathStr} ?????????? ${graphDest[startNode.id][endNode.id]}");
    await Future.delayed(const Duration(milliseconds: 1000));
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
  }

  _dijkstra(Node<num> startNode, Node<num> endNode) async {
    _clearLogs();
    _changeAllNode(ObjectState.idle);
    List<int> minDistance = [];
    List<int> visited = [];
    List<List<int>> graphDest = _getEdges();
    _changeToken(true);

    int beginIndex = startNode.id;

    int minIndex;
    int min;
    int temp;

    for (int i = 0; i < graphDest.length; i++) {
      minDistance.add(10000);
      visited.add(1);
    }
    minDistance[beginIndex] = 0;

    do {
      minIndex = 10000;
      min = 10000;
      _printSubs("?????????? ???? ?????? ???? ???????????????????? ????????????????");
      await Future.delayed(const Duration(milliseconds: 1000));
      for (int i = 0; i < graphDest.length; i++) {
        _printSubs(
            "???????? ?????????? ${graph[i].id} ${visited[i] == 1 ? "?????? ???? ????????????" : "?????? ????????????"}${visited[i] == 1 ? ", ?????? ?????????? ???? ?????? ?????????? ${minDistance[i] == 10000 ? "?????????????????????????? ????????????????" : minDistance[i]}" : ""}");
        await Future.delayed(const Duration(milliseconds: 1000));
        // ???????? ?????????????? ?????? ???? ???????????? ?? ?????? ???????????? min
        if ((visited[i] == 1) && (minDistance[i] < min)) {
          // ?????????????????????????????? ????????????????
          min = minDistance[i];
          minIndex = i;
          _printSubs("???????? ?????????? ${graph[minIndex].id}");
          _changeNodeState(graph[minIndex], ObjectState.select);
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      // ?????????????????? ?????????????????? ?????????????????????? ??????
      // ?? ???????????????? ???????? ??????????????
      // ?? ???????????????????? ?? ?????????????? ?????????????????????? ?????????? ??????????????
      if (minIndex != 10000) {
        for (int i = 0; i < graphDest.length; i++) {
          if (graphDest[minIndex][i] > 0) {
            _printSubs(
                "???????????????????? ???? ???????? $minIndex ???? ${i} ${graphDest[minIndex][i] == _maxInt ? "???????? ?????? ???? ????????????????????" : "?????????? ${graphDest[minIndex][i]}"}");
            await Future.delayed(const Duration(milliseconds: 1000));
            temp = min + graphDest[minIndex][i];
            if (temp < minDistance[i]) {
              _printSubs(
                  "?????????????? ???????????????????? ???????????????????? ???? ???????? $beginIndex ???? ${i} ?????????? ${temp}");
              minDistance[i] = temp;


              var node = _nodes.where((element) => element.node == graph[i]).first;

              setState(() {
                node.distance = temp;
                node.stateNow.changeState(node.stateNow.state);
              });

              await Future.delayed(const Duration(milliseconds: 1000));
            }
          }
        }
        visited[minIndex] = 0;
        // _printSubs("???????? ?????????? ${graph[minIndex].id}");
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } while (minIndex < 10000);

    List<int> ver = _findPath(
      beginIndex: beginIndex,
      endNodeId: endNode.id,
      minDistance: minDistance,
      graph: graphDest,
    );

    _changeAllNode(ObjectState.idle);
    _printSubs("?????????? ???????? ???? $beginIndex ???? ${endNode.id}");
    await Future.delayed(const Duration(milliseconds: 1000));
    await _showMinPath(ver, endNode.id, minDistance[endNode.id]);

    _removeDistanceFromNodes();
    _changeAllNode(ObjectState.idle);
    _changeToken(false);
    _printSubs("");
  }

  _removeDistanceFromNodes(){
    for(var node in _nodes) {
      setState(() {
        node.distance = null;
      });
    }
  }

  _findMaxStream(Node<num> startNode, Node<num> endNode) async {
    _changeAllNode(ObjectState.idle);
    List<int> maxDistance = [];
    List<int> visited = [];
    List<List<int>> graphDest = _getEdges(isMax: true);
    _changeToken(true);

    int beginIndex = startNode.id;

    int maxIndex;
    int max;
    int temp;

    for (int i = 0; i < graphDest.length; i++) {
      maxDistance.add(-1);
      visited.add(1);
    }
    maxDistance[beginIndex] = 0;

    do {
      maxIndex = -1;
      max = -1;
      for (int i = 0; i < graphDest.length; i++) {
        // ???????? ?????????????? ?????? ???? ???????????? ?? ?????? ???????????? max
        if ((visited[i] == 1) && (maxDistance[i] > max)) {
          // ?????????????????????????????? ????????????????
          max = maxDistance[i];
          maxIndex = i;
        }
      }
      // ?????????????????? ?????????????????? ???????????????????????? ??????
      // ?? ???????????????? ???????? ??????????????
      // ?? ???????????????????? ?? ?????????????? ?????????????????????? ?????????? ??????????????
      if (maxIndex != -1) {
        for (int i = 0; i < graphDest.length; i++) {
          if (graphDest[maxIndex][i] > 0) {
            temp = max + graphDest[maxIndex][i];
            if (temp > maxDistance[i] && visited[i] != 0) {
              maxDistance[i] = temp;
            }
          }
        }
        visited[maxIndex] = 0;
        _printSubs("???????? ?????????? ${graph[maxIndex].id}");
        _changeNodeState(graph[maxIndex], ObjectState.passed);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } while (maxIndex > -1);

    List<int> ver = _findPath(
      beginIndex: beginIndex,
      endNodeId: endNode.id,
      minDistance: maxDistance,
      graph: graphDest,
    );

    await _showMinPath(ver, endNode.id, maxDistance[endNode.id]);

    _changeAllNode(ObjectState.idle);
    _changeToken(false);
    _printSubs("");
  }

  _fordFulkersonAlgorithm(Node<num> startNode, Node<num> endNode) async {
    _clearLogs();
    _changeAllNode(ObjectState.idle);
    List<List<int>> graphDest = _getEdges(isMax: true);
    var edges = List<DistanceLineWidget>.of(_edges);
    List<List<int>> maxLenEdges = [];
    _changeToken(true);
    List<Tuple<Tuple<int, int>, int>> newEdgesList = [];

    for (var len in graphDest){
      maxLenEdges.add(List.of(len));
    }

    for (int i = 0; i < edges.length; i++) {
      var edge = edges[i];
      var edgeGraph = edge.edge;
      var newEdge = Edge(edgeGraph.from, edgeGraph.to, edgeGraph.value);
      edges[i] = DistanceLineWidget(
          edge: newEdge, graph: graph, to: edge.to, from: edge.from);
    }

    for (int i = 0; i < graphDest.length; i++) {
      for (int j = 0; j < graphDest.length; j++) {
        newEdgesList.add(Tuple(Tuple(i, j), 0));
      }
    }

    var path =
        await _maxFlow(graphDest, startNode.id, endNode.id, newEdgesList, maxLenEdges);

    _printSubs(
        "???????????????????????? ???????????????????? ????????????, ?????????????? ?????????? ?????????????? ???? ${startNode.id} ?? ${endNode.id} ?????????? $path");
    await Future.delayed(const Duration(milliseconds: 5000));

    setState(() {
      _edges.clear();
      _edges = edges;
    });

    _changeAllNode(ObjectState.idle);
    _changeToken(false);
    _printSubs("");
  }

  Future<int> _maxFlow(List<List<int>> cap, int s, int t,
      List<Tuple<Tuple<int, int>, int>> edgesList, List<List<int>> maxLenEdge) async {
    for (int flow = 0;;) {
      List<bool> visited = [];
      for (int i = 0; i < cap.length; i++) {
        visited.add(false);
      }
      int df = 0;
      await _findPathFordFulkerson(cap, visited, s, t, _maxInt, edgesList, maxLenEdge)
          .then((value) => df = value);
      if (df == 0) {
        return flow;
      }
      flow += df;
    }
  }

  Future<int> _findPathFordFulkerson(
      List<List<int>> graphEdges,
      List<bool> visited,
      int start,
      int end,
      int capacity,
      List<Tuple<Tuple<int, int>, int>> edgesList,
      List<List<int>> maxLenEdge) async {
    if (start == end) {
      _printSubs(
          "?????????? ?????????????????????????? ????????, ?????????? ???????????????? ?????????? ?????????????? $capacity ????????????");
      await Future.delayed(const Duration(milliseconds: 1500));
      return capacity;
    }
    _changeNodeState(graph[start], ObjectState.passed);
    _printSubs("???????????????? ?????????? ?????????? $start");
    await Future.delayed(const Duration(milliseconds: 1500));
    visited[start] = true;
    for (int v = 0; v < visited.length; v++) {
      _changeNodeState(graph[start], ObjectState.idle);
      if (!visited[v] && graphEdges[start][v] > 0) {
        int df = 0;
        await _findPathFordFulkerson(graphEdges, visited, v, end,
                min(capacity, graphEdges[start][v]), edgesList, maxLenEdge)
            .then((value) => df = value);

        _printSubs("?????????? $start ?? $v ?????????? ?????????????? $df");
        await Future.delayed(const Duration(milliseconds: 1500));
        if (df > 0) {
          _printSubs(
              "?????????? $start ?? $v ?????????? ?????????????? ??????, ?????????????????? $df ?? ????????????");
          _changeNodeState(graph[start], ObjectState.select);
          _changeNodeState(graph[v], ObjectState.select);
          await Future.delayed(const Duration(milliseconds: 1500));

          var value = edgesList
              .where((x) => x.item1.item1 == start && x.item1.item2 == v)
              .first;
          value.item2 += df;
          var maxValue = maxLenEdge[start][v];

          _printSubs(
              "???????????????????? ???????????? ???? $start ?? $v ???????????? ?????????? ${value.item2}");

          _changeEdges(value, maxValue.toString());
          await Future.delayed(const Duration(milliseconds: 1500));

          graphEdges[start][v] -= df;
          graphEdges[v][start] += df;

          _changeNodeState(graph[start], ObjectState.idle);
          _changeNodeState(graph[v], ObjectState.idle);
          return df;
        }
      }
    }
    _printSubs("???? $start ?? $end ???????????? ???? ??????????????");
    _changeNodeState(graph[start], ObjectState.idle);
    await Future.delayed(const Duration(milliseconds: 1500));

    return 0;
  }

  _changeEdges(Tuple<Tuple<int, int>, int> value, String maxValue) {
    if (!_edges.any((element) =>
        element.edge.from.id == value.item1.item1 &&
            element.edge.to.id == value.item1.item2 ||
        element.edge.from.id == value.item1.item2 &&
            element.edge.to.id == value.item1.item1)) {
      return;
    }
    setState(() {
      var edge = _edges
          .where((element) =>
              element.edge.from.id == value.item1.item1 &&
                  element.edge.to.id == value.item1.item2 ||
              element.edge.from.id == value.item1.item2 &&
                  element.edge.to.id == value.item1.item1)
          .first;

      _edges.remove(edge);
      edge.edge.value = "${value.item2}/$maxValue";

      _edges.add(edge);
    });
  }

  _showMinPath(List<int> ver, int endNodeId, int result) async {
    var path = ver[0] == endNodeId ? ver.reversed : ver;
    var pathStr = "";
    for (var nodePath in path) {
      var node = graph[nodePath];
      pathStr += nodePath == path.first ? "${node.id}" : " - ${node.id}";
      _printSubs("???????? ?????????? ?????????? ${node.id}");
      _changeNodeState(node, ObjectState.select);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    _printSubs("???????? ?????????? ?????????? $pathStr, ?????????? $result");
    await Future.delayed(const Duration(milliseconds: 3000));
  }

  List<int> _findPath(
      {required int beginIndex,
      required int endNodeId,
      required List<int> minDistance,
      required List<List<int>> graph}) {
    List<int> ver = []; // ???????????? ???????????????????? ????????????
    int end = endNodeId; // ???????????? ???????????????? ?????????????? = 5 - 1
    ver.add(end); // ?????????????????? ?????????????? - ???????????????? ??????????????
    int weight = minDistance[end]; // ?????? ???????????????? ??????????????

    while (end != beginIndex) // ???????? ???? ?????????? ???? ?????????????????? ??????????????
    {
      for (int i = 0; i < graph.length; i++) // ?????????????????????????? ?????? ??????????????
        if (graph[i][end] != 0 && graph[i][end] != -_maxInt) // ???????? ?????????? ????????
        {
          int temp = weight -
              graph[i][end]; // ???????????????????? ?????? ???????? ???? ???????????????????? ??????????????
          if (temp == minDistance[i]) // ???????? ?????? ???????????? ?? ????????????????????????
          {
            // ???????????? ???? ???????? ?????????????? ?? ?????? ??????????????
            weight = temp; // ?????????????????? ?????????? ??????
            end = i; // ?????????????????? ???????????????????? ??????????????
            ver.add(i); // ?? ???????????????????? ???? ?? ????????????
          }
        }
    }
    return ver;
  }

  List<List<int>> _getEdges({bool isMax = false}) {
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
          graphEdges[i].add(int.parse(
              nodes.where((element) => element.to.id == j).first.value));
        } else {
          var temp = isMax ? -_maxInt : _maxInt;
          graphEdges[i].add(temp);
        }
      }
    }

    return graphEdges;
  }

  _primsAlgorithm(Node<num> node) async {
    _clearLogs();
    List<List<int>> graphDest = _getEdges();
    List<Tuple<NodeWidget, NodeWidget>> tree = [];
    List<Node> treeNodes = [];
    var edges = List.of(_edges);

    _changeToken(true);

    List<bool> visited = [];

    for (int i = 0; i < graph.lenght; i++) {
      visited.add(false);
    }
    visited[node.id] = true;

    int x;
    int y;

    debugPrint("Edge : Weight");
    var size = graph.lenght;
    for (int i = 0; i < size - 1; i++) {
      int min = _maxInt;
      x = 0;
      y = 0;

      for (int i = 0; i < size; i++) {
        if (visited[i]) {
          for (int j = 0; j < size; j++) {
            if (i == j) {
              continue;
            }
            _printSubs("???????????????? ?????????????????? ?????????? $i ?? $j");
            await Future.delayed(const Duration(milliseconds: 1000));
            if (!treeNodes.contains(graph[j])) {
              _changeNodeState(graph[j], ObjectState.passed);
            }
            if (treeNodes.contains(graph[j])) {
              _printSubs("?????????????? $j ?????? ???????????????????????? ?? ???????????????? ????????????");
              await Future.delayed(const Duration(milliseconds: 1000));
              continue;
            }
            _printSubs(
                "?????????????????? ?????????? $i ?? $j ${graphDest[i][j] != 0 && graphDest[i][j] != _maxInt ? "?????????? ${graphDest[i][j]}" : "???????????????? ???? ????????????????????"}");
            await Future.delayed(const Duration(milliseconds: 1000));

            if (!visited[j] && graphDest[i][j] != 0) {
              if (min > graphDest[i][j]) {
                min = graphDest[i][j];
                x = i;
                y = j;
                _printSubs("?????????????????? ?????????? $i ?? $j ???????????????????? ??????????????????????");
                await Future.delayed(const Duration(milliseconds: 1000));
              }
            }
            if (!treeNodes.contains(graph[j])) {
              _changeNodeState(graph[j], ObjectState.idle);
            }
          }
        }
      }

      treeNodes.add(graph[x]);
      treeNodes.add(graph[y]);

      _printSubs("?????????????????????? ?????????????? $x -> $y");
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeNodeState(graph[y], ObjectState.select);
      _printSubs("?????????????????? $y ?? ?????????????????? ????????????");
      await Future.delayed(const Duration(milliseconds: 1000));
      var node1 = _nodes.where((element) => element.node == graph[x]).first;
      var node2 = _nodes.where((element) => element.node == graph[y]).first;

      tree.add(Tuple(node1, node2));

      debugPrint("$x - $y : ${graphDest[x][y]}");
      visited[y] = true;

      if (!treeNodes.contains(graph[x])) {
        _changeNodeState(graph[x], ObjectState.idle);
      }
    }
    setState(() {
      _edges.clear();
    });
    _printSubs("???????????????????? ?????????????????? ????????????");
    await Future.delayed(const Duration(milliseconds: 1000));

    await _buildPath(tree, graphDest);

    await Future.delayed(const Duration(milliseconds: 5000));

    _changeAllNode(ObjectState.idle);
    setState(() {
      _edges.clear();
      _edges = edges;
    });
    _printSubs("");
    _changeToken(false);
  }

  _buildPath(List<Tuple<NodeWidget, NodeWidget>> tree,
      List<List<int>> graphDest) async {
    for (var tuple in tree) {
      var node1 = tuple.item1.node;
      var node2 = tuple.item2.node;
      var value = graphDest[node1.id][node2.id];
      var edge = graph.connect(node1, node2, value);

      _printSubs("???????????????????? ???? ${node1.id} ?? ${node2.id} ???????????? ${value}");

      setState(() {
        _edges.add(DistanceLineWidget(
            edge: edge,
            graph: graph,
            to: tuple.item2.location,
            from: tuple.item1.location));
      });
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  Future<int> _showDialog() async {
    dynamic resultValue = -1;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('?????????????? ???????????????????? ?????????? ???????????????????? ????????????'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: '?????????????? ??????????',
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
      _showAlertDialog("?????? ???????? ?????? ??????????????????");
      setState(() {
        for (var node in _nodes) {
          node.stateNow.changeState(ObjectState.idle);
        }
        callback(null);
      });
    }
  }

  _selectNode(Function(Node<num>, Node<num>) action) {
    var selectNodes =
        _nodes.where((x) => x.stateNow.state == ObjectState.select).toList();
    if (selectNodes.length == 2 && !_isRun) {
      action.call(selectNodes[0].node, selectNodes[1].node);
      NodeWidget.selectedNodes.clear();
    } else if (selectNodes.length > 2) {
      _showAlertDialog("Warning: ?????????????? ????????????, ?????? ?????? ????????");
    } else {
      _showAlertDialog("Warning: ???? ?????????????? ??????????");
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
        ..._edges,
        ..._nodes,
        ..._additionalNodes,
        Positioned(
          bottom: 25,
          right: 25,
          child: Row(
            children: [
              Container(
                width: 400,
                height: 700,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.down,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      _logList[index],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  itemCount: _logList.length,
                ),
              ),
              Menu(
                depthSearch: () => _graphBypass(_depthSearch),
                breadthSearch: () => _graphBypass(_breadthSearch),
                openSubtitles: () => _openSubtitles(),
                saveFile: () => _saveFile(),
                uploadFile: () => _uploadFile(),
                minWay: () => _selectNode(_dijkstra),
                maxWay: () => _selectNode(_fordFulkersonAlgorithm),
                treeAlg: () => _graphBypass(_primsAlgorithm),
                addEdge: () => _selectNode(_addEdge),
              ),
            ],
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
