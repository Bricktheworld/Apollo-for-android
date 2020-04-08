import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:markdown/markdown.dart' as Markdown;
import 'package:flutter_html/flutter_html.dart';
import './pages/popup_web_view.dart';
import './dismissible.dart';
import './AuthModel.dart';
import './hex_color.dart';
import './expandable.dart';

class SlidableCommentTile extends StatefulWidget {
  final Comment comment;
  // final AuthModel model;
  final Function clearVote;
  final Function upVote;
  final Function onTap;
  final int depth;
  final List<Widget> children;

  SlidableCommentTile({
    Key key,
    this.comment,
    // this.model,
    this.clearVote,
    this.upVote,
    this.onTap,
    this.depth,
    this.children,
  }) : super(key: key);

  @override
  _SlidableCommentTileState createState() => _SlidableCommentTileState();
}

class _SlidableCommentTileState extends State<SlidableCommentTile>
    with AutomaticKeepAliveClientMixin<SlidableCommentTile> {
  double offset = 0;
  bool _pastThreshold = false;
  Color currentColor;
  bool _isCollapsed = false;
  bool _upvoted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _upvoted = widget.comment.vote == VoteState.upvoted;
  }

  _toggleVote() {
    setState(() {
      _upvoted = !_upvoted;
    });
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

  Color _getCurrentPullColor() {
    if (_pastThreshold) {
      if (offset.abs() > 0.3) {
        return HexColor('#23B5FF');
      } else {
        return Theme.of(context).secondaryHeaderColor;
      }
    } else {
      return Theme.of(context).backgroundColor;
    }
  }

  IconData _getCurrentIcon() {
    if (_pastThreshold) {
      if (offset.abs() > 0.3) {
        return Icons.reply;
      } else {
        return Icons.arrow_upward;
      }
    } else {
      return Icons.arrow_upward;
    }
  }

  Widget _mainComment() {
    return DismissibleCustom(
      background: Container(
        color: Theme.of(context).backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.center,
      ),
      secondaryBackground: Container(
        color: _getCurrentPullColor(),
        padding: EdgeInsets.only(right: 20),
        alignment: Alignment((1.2 + offset * 2), 0),
        child: Icon(
          _getCurrentIcon(),
          color: Colors.white,
          size: 20,
        ),
      ),
      dismissThresholds: {
        DismissDirection.endToStart: 0.1,
        DismissDirection.startToEnd: 1,
      },
      onDismissed: (direction, extent) {
        double percentage = extent.abs() / MediaQuery.of(context).size.width;
        if (percentage < 0.3) {
          _toggleVote();
        } else {}
      },
      onMove: (extent) {
        setState(() {
          offset = extent / MediaQuery.of(context).size.width;
          _pastThreshold = offset.abs() > 0.1;
          // if (_pastThreshold) {
          //   setState(() {
          //     currentColor = ;
          //   });
          // } else {
          //   setState(() {
          //     currentColor = Theme.of(context).backgroundColor;
          //   });
          // }
        });
      },
      movementDuration: Duration(milliseconds: 900),
      key: Key(widget.comment.id),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).accentColor.withOpacity(0.001),
              width: 1.5,
            ),
            // color: Theme.of(context).accentColor,
            // width: 1,
          ),
        ),
        padding: EdgeInsets.all(0),
        //main container for most of the comment
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.only(
            //adds the padding based on how far in the comment tree it is
            left: (widget.depth * 7).toDouble(),
          ),
          alignment: Alignment(-1, 0),
          //container for the main body of the comment
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      widget.comment.author,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(
                      flex: 3,
                    ),
                    Icon(
                      Icons.arrow_upward,
                      color: _upvoted
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).accentColor,
                      size: 15,
                    ),
                    Spacer(
                      flex: 1,
                    ),
                    Text(
                      widget.comment.upvotes.toString(),
                      style: TextStyle(
                        color: _upvoted
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).accentColor,
                        fontSize: 10,
                      ),
                    ),
                    Spacer(
                      flex: 50,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(
                    top: 0,
                  ),
                  child: AnimatedCrossFade(
                    duration: Duration(milliseconds: 350),
                    crossFadeState: _isCollapsed
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Container(),
                    secondChild: Html(
                      data: Markdown.markdownToHtml(widget.comment.body),
                      defaultTextStyle: TextStyle(
                        color: _isCollapsed
                            ? Theme.of(context).accentColor
                            : Colors.white,
                        fontSize: 13,
                      ),
                      onLinkTap: (String url) {
                        debugPrint(url);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PopupWebView(url: url),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 10,
              //this padding is necessary so that there is space between the text and the left border
              left: 5,
            ),
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(
                //if the comment is the main comment, then we dont need a border...
                width: widget.depth > 0 ? 1.5 : 0,
                color: Theme.of(context).accentColor.withOpacity(0.5),
              )),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTree() {
    List<Widget> tree = <Widget>[];
    // tree.add(_mainComment());
    tree.addAll(widget.children);
    return tree;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ExpandableNotifier(
      initialExpanded: true,
      child: ExpandablePanel(
        onChange: (val) {
          debugPrint(val.toString());
          setState(() {
            _isCollapsed = !val;
          });
        },
        header: _mainComment(),
        // collapsed: _mainComment(),
        expanded: Column(
          children: _buildTree(),
        ),
        hasIcon: false,
      ),
    );
  }
}
