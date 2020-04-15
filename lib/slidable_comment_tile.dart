import 'package:apollo/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
// import 'package:markdown/markdown.dart' as Markdown;
import 'package:markd/markdown.dart' as Markdown;
import 'package:flutter_html/flutter_html.dart';
import './pages/popup_web_view.dart';
import './dismissible.dart';
import './AuthModel.dart';
import './hex_color.dart';
import './expandable.dart';
import './page_route.dart';

class SlidableCommentTile extends StatefulWidget {
  final Comment comment;
  final Function onTap;
  final int depth;
  final List<Widget> children;

  SlidableCommentTile({
    Key key,
    this.comment,
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
  bool _isReplying = false;
  TextEditingController _controller;
  Markdown.ExtensionSet _extensionSet;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _upvoted = widget.comment.vote == VoteState.upvoted;
    });
    _controller = TextEditingController();
  }

  _toggleVote() {
    setState(() {
      _upvoted = !_upvoted;
    });
    if (widget.comment.vote == VoteState.upvoted) {
      try {
        widget.comment.clearVote();
        // _posts[index].clearVote();
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      try {
        widget.comment.upvote();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Color _getCurrentPullColor(bool threshold, currentOffset) {
    if (threshold) {
      if (currentOffset.abs() > 0.3) {
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
    String fixedBlockquote = widget.comment.body.replaceAll('&gt;', '>');
    _extensionSet = Markdown.ExtensionSet(
      <Markdown.BlockSyntax>[],
      <Markdown.InlineSyntax>[],
    );

    return Material(
      child: SplashView(
        // direction: DismissDirection.endToStart,
        splashFactory: InkRipple.splashFactory,
        splashColor:
            _getCurrentPullColor(_pastThreshold, offset).withOpacity(0.5),
        background: Container(
          color: Theme.of(context).backgroundColor,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: AlignmentDirectional.center,
        ),
        secondaryBackground: Container(
          color: _getCurrentPullColor(_pastThreshold, offset),
          padding: EdgeInsets.only(right: 20),
          // alignment: Alignment((1.2 + offset * 2), 0),
          alignment: AlignmentDirectional.centerEnd,
          child: Icon(
            _getCurrentIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        // dismissThresholds: {
        //   DismissDirection.endToStart: 0.1,
        //   DismissDirection.startToEnd: 1,
        // },
        onDismissed: (direction, extent) {
          double percentage = extent.abs() / MediaQuery.of(context).size.width;
          if (percentage < 0.3) {
            _toggleVote();
          } else {
            setState(() {
              _isReplying = !_isReplying;
              if (!_isReplying) {
                FocusScope.of(context).unfocus();
              }
            });
            debugPrint(widget.comment.body);
            String fixedBlockquote =
                widget.comment.body.replaceAll('&gt;', '>');

            debugPrint(Markdown.markdownToHtml(fixedBlockquote,
                extensionSet: Markdown.ExtensionSet.gitHubWeb,
                inlineSyntaxes: [
                  Markdown.CodeSyntax(),
                  Markdown.AutolinkExtensionSyntax()
                ],
                blockSyntaxes: [
                  Markdown.BlockquoteSyntax(),
                  Markdown.CodeBlockSyntax(),
                ]));
          }
        },
        onMove: (extent) {
          var beforePullColor = _getCurrentPullColor(_pastThreshold, offset);
          offset = extent / MediaQuery.of(context).size.width;
          _pastThreshold = offset.abs() > 0.1;
          if (beforePullColor != _getCurrentPullColor(_pastThreshold, offset)) {
            debugPrint("update past threshold");
            setState(() {});
          }
        },
        // movementDuration: Duration(milliseconds: 400),
        key: Key(widget.comment.id),
        child: Container(
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
                        data: Markdown.markdownToHtml(
                          fixedBlockquote,
                          extensionSet: Markdown.ExtensionSet.gitHubWeb,
                          inlineSyntaxes: [
                            Markdown.CodeSyntax(),
                            Markdown.AutolinkExtensionSyntax(),
                          ],
                          blockSyntaxes: [
                            Markdown.BlockquoteSyntax(),
                            Markdown.CodeBlockSyntax(),
                          ],
                        ),
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
                            TransparentRoute(
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
                  ),
                  bottom: BorderSide(
                    width: 1,
                    color: Theme.of(context).accentColor.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTree() {
    List<Widget> tree = <Widget>[];
    // tree.add(_mainComment());
    tree.add(_buildReplyMenu());
    tree.addAll(widget.children);
    return tree;
  }

  Widget _buildReplyMenu() {
    return AnimatedCrossFade(
      firstChild: Container(),
      secondChild: Material(
        color: Theme.of(context).primaryColor,
        child: Material(
          child: Container(
            padding: EdgeInsets.only(
              left: ((widget.depth + 1) * 7).toDouble(),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    //if the comment is the main comment, then we dont need a border...
                    width: 1.5,
                    color: Theme.of(context).accentColor.withOpacity(0.5),
                  ),
                  bottom: BorderSide(
                    width: 1,
                    color: Theme.of(context).accentColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Card(
                color: HexColor("232a38"),
                child: Column(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color:
                                Theme.of(context).accentColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          IconButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _isReplying = false;
                              });
                            },
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              widget.comment
                                  .reply(_controller.value.text)
                                  .whenComplete(() {
                                _controller.value = TextEditingValue(text: "");
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _isReplying = false;
                                });
                              }).catchError((e) {
                                debugPrint(e.toString());
                              });
                            },
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).accentColor,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          // border: OutlineInputBorder(),
                          hintText: 'Type a reply...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      crossFadeState:
          _isReplying ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 100),
    );
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
