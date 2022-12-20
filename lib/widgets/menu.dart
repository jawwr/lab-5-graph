import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  final Function() depthSearch;
  final Function() breadthSearch;
  final Function() saveFile;
  final Function() uploadFile;
  final Function() openSubtitles;
  final Function() minWay;
  final Function() addEdge;
  final Function() maxWay;
  final Function() treeAlg;

  const Menu(
      {Key? key,
      required this.depthSearch,
      required this.breadthSearch,
      required this.saveFile,
      required this.uploadFile,
      required this.openSubtitles,
      required this.minWay,
      required this.addEdge,
      required this.maxWay,
      required this.treeAlg})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _Menu();
}

class _Menu extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MenuIcon(
            func: widget.addEdge,
            icon: Icons.arrow_right_alt_outlined,
          ),
          _MenuIcon(
            func: widget.depthSearch,
            icon: Icons.swap_vert,
          ),
          _MenuIcon(
            func: widget.breadthSearch,
            icon: Icons.swap_horiz,
          ),
          _MenuIcon(
            func: widget.maxWay,
            icon: Icons.map_outlined,
          ),
          _MenuIcon(
            func: widget.treeAlg,
            icon: Icons.forest,
          ),
          _MenuIcon(
            func: widget.minWay,
            icon: Icons.map,
          ),
          _MenuIcon(
            func: widget.uploadFile,
            icon: Icons.cloud_upload,
          ),
          _MenuIcon(
            func: widget.saveFile,
            icon: Icons.cloud_download,
          ),
          _MenuIcon(
            func: widget.openSubtitles,
            icon: Icons.closed_caption,
          ),
        ],
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({Key? key, required this.func, required this.icon})
      : super(key: key);

  final void Function() func;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        child: Material(
          clipBehavior: Clip.hardEdge,
          color: Colors.teal,
          borderRadius: BorderRadius.all(Radius.circular(50)),
          child: IconButton(
            iconSize: 50,
            onPressed: func,
            icon: Icon(icon),
            splashColor: Colors.transparent,
            color: Colors.white,
            highlightColor: Colors.pink,
          ),
        ));
  }
}
