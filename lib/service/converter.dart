import 'dart:math';

import 'package:lab_5/DTO/graph_dto.dart';

import 'graph_logic.dart';

extension Converter on String {
  Tuple<Graph<num>, Map<Node<num>, Point>> convertToGraph(bool isOriented) {
    var arrays = split(';');
    var matrix = arrays[0].split('\n');
    var graph = Graph<num>(matrix.length, isOriented);
    for (int i = 0; i < matrix.length; i++) {
      var row = matrix[i].trim().split(' ');
      for (int j = 0; j < row.length; j++) {
        var res = int.tryParse(row[j]);
        if (res != null && res > 0) {
          graph.connect(graph.nodes.toList()[i], graph.nodes.toList()[j], res);
        }
      }
    }
    var points = arrays[1].trim().split('\n');
    Map<Node<num>, Point> map = {};
    for (int i = 0; i < points.length; i++) {
      var info = points[i].trim().split(' ');
      var res = int.tryParse(info[0]);
      var x = double.tryParse(info[1]);
      var y = double.tryParse(info[2]);
      if (res != null && x != null && y != null) {
        map[graph[res]] = Point(x, y);
      }
    }
    return Tuple(graph, map);
  }

  Tuple<Graph<num>, Map<Node<num>, Point>> convertDtoToGraph(
      GraphDTO dto, bool isOriented) {
    var points = dto.nodes!;
    var edges = dto.edges!;
    var graph = Graph<num>(points.length, isOriented);
    for (int i = 0; i < edges.length; i++) {
      graph.connect(
          graph[edges[i].idFrom!], graph[edges[i].idTo!], edges[i].value!);
    }

    Map<Node<num>, Point> map = {};
    for (int i = 0; i < points.length; i++) {
      var res = points[i].id;
      var x = points[i].xCord;
      var y = points[i].yCord;
      if (res != null && x != null && y != null) {
        var a = graph[res];
        map[graph[res]] = Point(x, y);
      }
    }
    return Tuple(graph, map);
  }
}

GraphDTO convertGraphToDTO(Graph graph, Map<Node<num>, Point> nodePos) {
  GraphDTO dto = GraphDTO();
  List<NodeDTO> nodesDTo = [];
  for (var node in graph.nodes) {
    nodesDTo.add(NodeDTO(
      id: node.id,
      xCord: nodePos[node]!.x.floor(),
      yCord: nodePos[node]!.y.floor(),
    ));
  }
  dto.nodes = nodesDTo;

  List<EdgeDTO> edgesDTO = [];
  for (var edge in graph.edges) {
    edgesDTO.add(EdgeDTO(
      idFrom: edge.from.id,
      idTo: edge.to.id,
      value: int.parse(edge.value),
    ));
  }
  dto.edges = edgesDTO;

  return dto;
}
