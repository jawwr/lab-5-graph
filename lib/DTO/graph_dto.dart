import 'dart:convert';

GraphDTO graphDTOFromJson(String str) => GraphDTO.fromJson(json.decode(str));

String graphDTOToJson(GraphDTO data) => json.encode(data.toJson());

class GraphDTO {
  List<NodeDTO>? nodes;
  List<EdgeDTO>? edges;

  GraphDTO({this.nodes, this.edges});

  GraphDTO.fromJson(Map<String, dynamic> json) {
    if (json['nodes'] != null) {
      nodes = <NodeDTO>[];
      json['nodes'].forEach((v) {
        nodes!.add(new NodeDTO.fromJson(v));
      });
    }
    if (json['edges'] != null) {
      edges = <EdgeDTO>[];
      json['edges'].forEach((v) {
        edges!.add(new EdgeDTO.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.nodes != null) {
      data['nodes'] = this.nodes!.map((v) => v.toJson()).toList();
    }
    if (this.edges != null) {
      data['edges'] = this.edges!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NodeDTO {
  int? id;
  int? xCord;
  int? yCord;

  NodeDTO({this.id, this.xCord, this.yCord});

  NodeDTO.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    xCord = json['xCord'];
    yCord = json['yCord'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['xCord'] = this.xCord;
    data['yCord'] = this.yCord;
    return data;
  }
}

class EdgeDTO {
  int? idFrom;
  int? idTo;
  int? value;

  EdgeDTO({this.idFrom, this.idTo, this.value});

  EdgeDTO.fromJson(Map<String, dynamic> json) {
    idFrom = json['idFrom'];
    idTo = json['idTo'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idFrom'] = this.idFrom;
    data['idTo'] = this.idTo;
    data['value'] = this.value;
    return data;
  }
}
