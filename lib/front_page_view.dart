import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import './login_screen.dart';
import './slidable_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrontPageView extends StatefulWidget {
  final Reddit reddit;
  final Function updateClient;

  const FrontPageView({Key key, this.reddit, this.updateClient})
      : super(key: key);

  @override
  _FrontPageViewState createState() => _FrontPageViewState();
}

class _FrontPageViewState extends State<FrontPageView> {
  List<Submission> _posts = <Submission>[];
  Redditor currentUser;
  StreamSubscription<UserContent> stream;
  var _postsTemp = <Submission>[];

  // var reddit;

  @override
  void initState() {
    super.initState();
    _attemptToAutoLogIn();
  }

  _attemptToAutoLogIn() async {
    if (widget.reddit != null)
      debugPrint(widget.reddit.auth.isValid.toString());
    final userAgent = 'randomly_generated_user_agent';
    final credentialsJson = await loadCredentials();
    if (credentialsJson != null) {
      if (widget.reddit == null || !widget.reddit.auth.isValid) {
        Reddit redditTemp = Reddit.restoreAuthenticatedInstance(credentialsJson,
            userAgent: userAgent,
            clientId: 'zSdAudnVnFwgeQ',
            clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs');
        widget.updateClient(redditTemp);
        currentUser = await redditTemp.user.me();
      }
      _postsTemp = <Submission>[];
      await startFetching();
    }
  }

  _initUser() async {
    final userAgent = 'randomly_generated_user_agent';
    final configUri = Uri.parse('draw.ini');
    final credentialsJson = await loadCredentials();
    if (credentialsJson == null) {
      Reddit redditTemp = Reddit.createWebFlowInstance(
          userAgent: userAgent,
          configUri: configUri,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs',
          redirectUri: Uri.parse("https://www.reddit.com/r/android"));
      widget.updateClient(redditTemp);

      final authUrl = redditTemp.auth
          .url(['*'], 'aslkdjflakwejfoiaehroijaewofire', compactLogin: true);
      debugPrint(authUrl.toString());

      return authUrl.toString();
    } else {
      Reddit redditTemp = Reddit.restoreAuthenticatedInstance(credentialsJson,
          userAgent: userAgent,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs');
      widget.updateClient(redditTemp);
      await startFetching();
      return "already logged in";
    }
  }

  _authUser(authCode) async {
    await widget.reddit.auth.authorize(authCode);
    await writeCredentials(widget.reddit.auth.credentials.toJson());
    currentUser = await widget.reddit.user.me();
    debugPrint(widget.reddit.auth.credentials.toJson());
    Navigator.of(context).pop();
    await startFetching();
  }

  loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint(prefs.getString('credentials'));
    return prefs.getString('credentials');
  }

  writeCredentials(cred) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('credentials', cred);
  }

  cacheSubreddits(subreddits) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('subreddits', subreddits);
  }

  startFetching() async {
    _postsTemp = <Submission>[];
    setState(() {
      _posts = <Submission>[];
    });
    debugPrint('begin fetching posts');
    try {
      stream = currentUser.reddit.front.best().listen((s) async {
        _posts.add(s);
        setState(() {});
        if (_posts.length > 700) stream.pause();
        // debugPrint('new post: ' + i.toString());
      });
    } catch (e) {}
  }

  // addPost(data) {
  //   Submission post = Submission.parse(reddit, data);
  //   _postsTemp.add(post);
  //   debugPrint(_postsTemp.length.toString());
  //   if (_postsTemp.length >= 0) {
  //     setState(() {
  //       _posts = _postsTemp;
  //     });
  //   }
  //   if (_posts.length >= 1000) {
  //     stream.pause();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            elevation: 0.0,
            title: new Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text('Front Page',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    )),
              ],
            )),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
        body: _buildList());
  }

  _buildList() {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView.builder(
        shrinkWrap: false,
        // separatorBuilder: (context, index) {
        //   return Divider(
        //     indent: 30.0,
        //     endIndent: 30.0,
        //     height: 1,
        //     color: Colors.white24,
        //   );
        // },
        physics: BouncingScrollPhysics(),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          Submission post = _posts[index];
          return SlidableListTile(
            post: post,
            upVote: () => post.upvote(),
            clearVote: () => post.clearVote(),
            numComments: 0,
          );
        },
      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            onPressed: () async {
              // _initUser();
              if (widget.reddit != null) {
                stream.cancel();
                await startFetching();
              } else {
                String url = await _initUser();
                debugPrint('opening');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginScreen(
                            loginUri: url,
                            redirectUri: "https://www.reddit.com/r/android",
                            callback: (data) => {_authUser(data)})));
              }
              // Add your onPressed code here!
            },
            child: Icon(Icons.navigation),
            backgroundColor: Colors.green,
          )),
    );
  }
}
