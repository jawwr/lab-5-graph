import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  final Function() depthSearch;
  final Function() breadthSearch;
  final Function() saveFile;
  final Function() uploadFile;
  final Function() openSubtitles;

  const Menu({
    Key? key,
    required this.depthSearch,
    required this.breadthSearch,
    required this.saveFile,
    required this.uploadFile,
    required this.openSubtitles,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Menu();
}

class _Menu extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MenuIcon(
            func: widget.depthSearch,
            icon: Icons.swap_vert,
          ),
          _MenuIcon(
            func: widget.breadthSearch,
            icon: Icons.swap_horiz,
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