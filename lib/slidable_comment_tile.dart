import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import './dismissible.dart';
import './AuthModel.dart';
import './hex_color.dart';

class SlidableCommentTile extends StatefulWidget {
  final Comment comment;
  final AuthModel model;
  final Function clearVote;
  final Function upVote;
  final Function onTap;

  SlidableCommentTile(
      {Key key,
      this.comment,
      this.model,
      this.clearVote,
      this.upVote,
      this.onTap})
      : super(key: key);

  @override
  _SlidableCommentTileState createState() => _SlidableCommentTileState();
}

class _SlidableCommentTileState extends State<SlidableCommentTile> {
  double offset = 0;
  bool _pastThreshold = false;

  bool _toggleVote() {
    if (widget.comment.vote == VoteState.upvoted) {
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
        secondaryBackground: TweenAnimationBuilder(
          builder: (_, double size, __) {
            return Container(
                color: offset.abs() < 0.4
                    ? Theme.of(context).secondaryHeaderColor
                    : HexColor('00AC37'),
                padding: EdgeInsets.only(right: 20),
                alignment: Alignment((1.2 + offset / 2).clamp(1.0, 1.2), 0),
                child: Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: size,
                ));
          },
          tween: Tween<double>(begin: 0, end: _pastThreshold ? 40 : 0),
          curve: ElasticOutCurve(0.2),
          duration: Duration(seconds: 1),
        ),
        dismissThresholds: {
          DismissDirection.endToStart: 0.2,
          DismissDirection.startToEnd: 1,
        },
        onDismissed: (direction, extent) {
          double percentage = extent.abs() / MediaQuery.of(context).size.width;
          if (percentage < 0.4) {
            _toggleVote();
          } else {}
        },
        onMove: (extent) {
          setState(() {
            offset = extent / MediaQuery.of(context).size.width;
            _pastThreshold = offset.abs() > 0.2;
          });
        },
        movementDuration: Duration(milliseconds: 200),
        key: Key(widget.comment.id),
        child: Container(
            padding: EdgeInsets.all(0),
            child: Material(
              color: Theme.of(context).primaryColor,
              // elevation: 2,
              child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (widget.onTap != null) widget.onTap();
                  },
                  child: Row(
                    children: <Widget>[
                      Container(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Container(
                                  alignment: Alignment(-1, 0),
                                  child: Text(widget.comment.author,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13))),
                            ]),
                        // alignment: AlignmentDirectional(-1, 1),
                        width: 240,
                      ),
                    ],
                  )),
            )));
  }
}
