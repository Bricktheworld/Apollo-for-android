import 'dart:convert';
import 'package:apollo/AuthModel.dart';
import 'package:apollo/post_view.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:http/http.dart' as http;

import '../custom_app_bar.dart';
import '../page_route.dart';

class SearchPageView extends StatefulWidget {
  final AuthModel model;
  SearchPageView({Key key, this.model}) : super(key: key);

  @override
  _SearchPageViewState createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _searchPost() async {
    String postID = SubmissionRef.idFromUrl(Uri.parse(
        'https://amp.reddit.com/branch-redirect?creative=AppSelectorModal&experiment=app_selector_contrast_iteration&path=%2Fr%2Fhardware%2Fcomments%2F9zermh%2Fcheap_mechanical_keyboard_buyers_guide%2F&variant=blue_header'));
    SubmissionRef submissionRef =
        SubmissionRef.withID(widget.model.reddit, postID);
    Submission submission = await submissionRef.populate();

    // Submission submission = Submission.parse(
    //   widget.model.reddit,
    //   parsedJson,
    // );
    Navigator.push(
        context,
        TransparentRoute(
            builder: (context) => PostView(
                  submission: submission,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: CustomAppBar(title: 'Search'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          onPressed: () async {
            _searchPost();
          },
          child: Icon(Icons.refresh),
          backgroundColor: Theme.of(context).secondaryHeaderColor,
        ),
      ),
    );
  }
}
