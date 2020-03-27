import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import './dismissible.dart';
import 'dart:core';
import './hex_color.dart';

class SlidableListTile extends StatefulWidget {
  final Submission post;
  final Function clearVote;
  final Function upVote;
  final double numComments;

  const SlidableListTile(
      {Key key, this.post, this.clearVote, this.upVote, this.numComments})
      : super(key: key);

  @override
  _SlidableListTileState createState() => _SlidableListTileState();
}

class _SlidableListTileState extends State<SlidableListTile> {
  double offset = 0;

  bool _toggleVote() {
    if (widget.post.vote == VoteState.upvoted) {
      try {
        widget.clearVote();
        // _posts[index].clearVote();
      } catch (e) {}
    } else {
      try {
        widget.upVote();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleCustom(
        background: Container(
          color: Theme.of(context).backgroundColor,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: AlignmentDirectional.center,
        ),
        secondaryBackground: Container(
            color: Theme.of(context).secondaryHeaderColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment(1.2 + offset, 0),
            // AlignmentDirectional.centerEnd,
            child: Icon(
              Icons.arrow_upward,
              color: Colors.white,
            )),
        dismissThresholds: {
          DismissDirection.endToStart: 0.1,
          DismissDirection.startToEnd: 1,
        },
        onDismissed: (direction, extent) {
          double percentage = extent.abs() / MediaQuery.of(context).size.width;
          if (percentage < 0.4) {
            _toggleVote();
          }
        },
        onMove: (extent) {
          setState(() {
            offset = extent / MediaQuery.of(context).size.width;
          });
        },
        movementDuration: Duration(milliseconds: 200),
        key: Key(widget.post.id),
        child: Container(
            padding: EdgeInsets.all(0),
            child: Material(
              color: Theme.of(context).primaryColor,
              // elevation: 2,
              child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {},
                  child: Row(
                    children: <Widget>[
                      widget.post.thumbnail == null
                          ? Icon(Icons.filter)
                          : Container(
                              alignment: Alignment.topCenter,
                              padding: EdgeInsets.all(10),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.network(
                                      widget.post.thumbnail.toString(),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.fitHeight))),
                      Container(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Container(
                                  alignment: Alignment(-1, 0),
                                  child: Text(widget.post.title,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13))),
                              Container(
                                  margin: const EdgeInsets.only(
                                    top: 10,
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                  ),
                                  child: Column(children: <Widget>[
                                    Container(
                                        alignment: Alignment(-1, 0),
                                        child: Text(
                                          widget.post.subreddit.displayName,
                                          style: TextStyle(
                                              color: HexColor('7b7f8a'),
                                              fontSize: 11),
                                        )),
                                    Row(
                                      children: <Widget>[
                                        Text(widget.post.upvotes.toString(),
                                            style: TextStyle(
                                                color: HexColor('7b7f8a'),
                                                fontSize: 11)),
                                        Text(widget.numComments.toString(),
                                            style: TextStyle(
                                                color: HexColor('7b7f8a'),
                                                fontSize: 11)),
                                      ],
                                    )
                                  ])),
                            ]),
                        // alignment: AlignmentDirectional(-1, 1),
                        width: 240,
                      ),
                    ],
                  )),
              // child: ListTile(
              //   isThreeLine: true,
              //   enabled: true,
              //   onTap: () {
              //     // do something
              //     return true;
              //   },
              //   onLongPress: () {
              //     // do something else
              //   },
              //   leading: CircleAvatar(
              //     child: Container(
              //       width: 80,
              //       child: widget.post.thumbnail == null
              //           ? Icon(Icons.filter)
              //           : Image.network(widget.post.thumbnail.toString(),
              //               width: 200, height: 100, fit: BoxFit.fitHeight),
              //     ),
              //   ),
              //   title: Text(
              //     widget.post.title,
              //     style: TextStyle(fontSize: 12, color: Colors.white),
              //   ),
              //   subtitle: Text('subtitle'),
              // )
            )));
  }
}
