import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import './AuthModel.dart';

class PostView extends StatefulWidget {
  Submission submission;
  PostView({Key key, this.submission}) : super(key: key);

  @override
  _PostViewState createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Container(),
      ),
    );
  }
}
