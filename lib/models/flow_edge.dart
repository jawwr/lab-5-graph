import '../service/graph_logic.dart';

class FlowEdge{
  Node<num> node;
  int flow;
  int capacity;

  get getCapacity => capacity - flow;

  FlowEdge(this.node, this.flow, this.capacity);
}