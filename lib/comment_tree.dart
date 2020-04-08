import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import './slidable_comment_tile.dart';

class CommentTree extends StatefulWidget {
  final comment;

  CommentTree({Key key, this.comment}) : super(key: key);

  @override
  _CommentTreeState createState() => _CommentTreeState();
}

class _CommentTreeState extends State<CommentTree> {
  @override
  Widget build(BuildContext context) {
    return _buildTree(widget.comment, 0);
  }

  //i swear to god if flutter did not support recursive creation of widgets...
  //you dont understand the nightmares i went through trying to plan this out
  //all the terror of "how the fuck would i implement this without recursion"
  //the fucking sleepless nights around this

  //never thought i'd say this but thank fuck for google
  _buildTree(Comment _comment, int depth) {
    List<Widget> tree = <Widget>[];
    if (_comment.replies != null) {
      try {
        for (int i = 0; i < _comment.replies.length; i++) {
          tree.add(
            _buildTree(
              _comment.replies[i],
              depth + 1,
            ),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return SlidableCommentTile(
      comment: _comment,
      depth: depth,
      children: tree,
    );
  }
}
