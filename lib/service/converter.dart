import 'dart:math';

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
}
