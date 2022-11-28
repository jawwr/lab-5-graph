class Graph<num> {
  late final bool isOriented;
  int _edgeLenght = 0;
  List<Node<num>> _nodes = [];
  Graph(int nodesCount, this.isOriented) {
    _nodes = Iterable.generate(nodesCount).map((e) => Node<num>(e)).toList();
  }
  Graph.def(this.isOriented);
  int get lenght => _nodes.length;
  int get edgeLenght => _edgeLenght;
  Iterable<Node<num>> get nodes => _nodes;
  Iterable<Edge<num>> get edges => edgeLenght > 0
      ? isOriented
      ? _nodes
      .map((x) => x.incidentEdges)
      .reduce((x, element) => x.toList() + element.toList())
      : _nodes.map((x) => x.incidentEdges).reduce((x, element) =>
  x
      .where((t) => element.every((element) => element != t))
      .toList() +
      element.toList())
      : [];

  void addNode(value) {
    if (value is num) {
      _nodes.add(Node(value));
    }
    if (value is Node<num>) {
      _nodes.add(value);
    } else {
      throw FormatException("incorrect params");
    }
  }

  void removeNode(value) {
    void remove(Node<num> node) {
      for (var edge in node.incidentEdges.toList()) {
        disconect(edge);
      }
      _nodes.remove(node);
    }

    if (value is num) {
      remove(this[value as int]);
    }
    if (value is Node<num>) {
      remove(value);
    } else {
      throw FormatException("incorrect params");
    }
  }

  Edge<num> connect(Node<num> node1, Node<num> node2, num edgeValue) {
    var eadges = Node.connect<num>(node1, node2, this, edgeValue);
    _edgeLenght += 1;
    if (isOriented) {
      node1._edges.add(eadges.item1);
    } else {
      if (node1.id == node2.id) {
        node1._edges.add(eadges.item1);
      } else {
        node1._edges.add(eadges.item1);
        node2._edges.add(eadges.item2);
      }
    }
    return eadges.item1;
  }

  void disconect(Edge<num> edge) {
    _edgeLenght -= isOriented ? 2 : 1;
    Node.disconect(edge);
  }

  Node<num> operator [](int index) {
    return _nodes[index];
  }

  static Graph<num> makeGraph<num>(
      List<Tuple<Node<num>, Node<num>>> incidentNodes, List<num> values,
      {bool isOriented = false}) {
    if (incidentNodes.length == values.length) {
      var graph = Graph<num>.def(isOriented);
      int i = 0;
      for (var element in incidentNodes) {
        if (!graph.nodes.contains(element.item1)) {
          graph.addNode(element.item1);
        }
        if (!graph.nodes.contains(element.item2)) {
          graph.addNode(element.item2);
        }
        graph.connect(element.item1, element.item2, values[i]);
        i++;
      }
      return graph;
    } else {
      throw Exception("incorrect parameters");
    }
  }
}

class Node<num> {
  late final List<Edge<num>> _edges;
  late final num _number;
  int _id = 0;
  Node(this._number) {
    _id = _counter;
    _counter++;
    _edges = [];
  }
  num get number => _number;
  int get id => _id;
  Iterable<Node<num>> get incidentNodes => _edges.map((e) => e.otherNode(this));
  Iterable<Edge<num>> get incidentEdges => _edges.map((e) => e);
  num? getValueLinkNode(Node<num> node) {
    var edge = incidentEdges.where((x) => x.isIncident(node));
    if (edge.isNotEmpty) {
      return edge.first.value;
    } else {
      return null;
    }
  }

  static int _counter = 1;
  static Tuple<Edge<num>, Edge<num>> connect<num>(
      Node<num> node1, Node<num> node2, Graph<num> graph, num value) {
    if (!graph.nodes.contains(node1) || !graph.nodes.contains(node2)) {
      throw FormatException("incorect node");
    }
    var edge1 = Edge<num>(node1, node2, value);
    var edge2 = Edge(node2, node1, value);
    return Tuple(edge1, edge2);
  }

  static void disconect<num>(Edge<num> edge) {
    edge.from._edges.remove(edge);
    edge.to._edges.remove(edge);
  }

  @override
  bool operator ==(other) {
    return other is Node<num> && _id == other.id;
  }

  @override
  int get hashCode => _id;
}

class Edge<num> {
  static const int maxValue = 10000;
  late final Node<num> from;
  late final Node<num> to;
  late final num value;
  @override
  int get hashCode => to.hashCode;
  Edge(this.from, this.to, num value) {
    if (value as int > maxValue) {
      throw Exception("Incorect value of Node");
    } else {
      this.value = value;
    }
  }

  bool isIncident(Node<num> node) {
    return from == node || to == node;
  }

  Node<num> otherNode(Node<num> node) {
    if (isIncident(node) && value != null) {
      if (from == node) {
        return to;
      } else {
        return from;
      }
    } else {
      throw FormatException("incorect value");
    }
  }

  @override
  bool operator ==(other) {
    return other is Edge<num> &&
        [other.to.id, other.from.id].contains(to.id) &&
        [other.to.id, other.from.id].contains(from.id);
  }
}

class Tuple<T1, T2> {
  Tuple(this.item1, this.item2);

  Tuple.fromJson(Map<String, dynamic> json) {
    item1 = json['item1'];
    item2 = json['item2'];
  }

  Map<String, dynamic> toJson() => {
    'item1': item1,
    'item2': item2,
  };
  late T1 item1;
  late T2 item2;
}
