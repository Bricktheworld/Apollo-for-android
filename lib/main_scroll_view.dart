import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:draw/draw.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import './login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScrollView extends StatefulWidget {
  @override
  _MainScrollViewState createState() => _MainScrollViewState();
}

class _MainScrollViewState extends State<MainScrollView> {
  List<Post> _posts = <Post>[];
  Redditor currentUser;
  StreamSubscription<UserContent> stream;
  var _postsTemp = <Post>[];

  String _token;
  var reddit;

  @override
  void initState() {
    super.initState();
    // _initUser();
    _attemptToAutoLogIn();
  }

  _attemptToAutoLogIn() async {
    final userAgent = 'randomly_generated_user_agent';
    final credentialsJson = await loadCredentials();
    if (credentialsJson != null) {
      reddit = Reddit.restoreAuthenticatedInstance(credentialsJson,
          userAgent: userAgent,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs');
      await startFetching();
    }
  }

  _initUser() async {
    final userAgent = 'randomly_generated_user_agent';
    final configUri = Uri.parse('draw.ini');
    final credentialsJson = await loadCredentials();
    if (credentialsJson == null) {
      reddit = Reddit.createWebFlowInstance(
          userAgent: userAgent,
          configUri: configUri,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs',
          redirectUri: Uri.parse("https://www.reddit.com/r/android"));

      final auth_url = reddit.auth
          .url(['*'], 'aslkdjflakwejfoiaehroijaewofire', compactLogin: true);
      debugPrint(auth_url.toString());

      return auth_url.toString();

      // Extract token from resulting url

      // await reddit.auth.authorize(auth_code);
      // await writeCredentials(reddit.auth.credentials.toJson());
      // debugPrint(reddit.auth.credentials.toJson());
    } else {
      reddit = Reddit.restoreAuthenticatedInstance(credentialsJson,
          userAgent: userAgent,
          clientId: 'zSdAudnVnFwgeQ',
          clientSecret: 'ie1HFUPU4ot57BnRD9f1HECL2rs');
      await startFetching();
      return "already logged in";
    }
  }

  _authUser(auth_code) async {
    await reddit.auth.authorize(auth_code);
    await writeCredentials(reddit.auth.credentials.toJson());
    currentUser = await reddit.user.me();
    debugPrint(reddit.auth.credentials.toJson());
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

  startFetching() async {
    currentUser = await reddit.user.me();
    _postsTemp = <Post>[];
    stream = currentUser.reddit.front.best().listen((data) => addPost(data));
    debugPrint("My name is ${currentUser.displayName}");
  }

  addPost(data) {
    // debugPrint(data.toString());
    Post post = new Post();
    post.title = data.title;
    post.thumbnail = data.thumbnail.toString();

    _postsTemp.add(post);
    debugPrint(_postsTemp.length.toString());
    if (_postsTemp.length >= 0) {
      // stream.pause();
      setState(() {
        _posts = _postsTemp;
      });
      // _postsTemp = <Post>[];
    }
    if (_posts.length >= 1000) {
      stream.pause();
    }
  }

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
      backgroundColor: Theme.of(context).primaryColor,
      body: ListView.separated(
        separatorBuilder: (context, index) {
          return Divider(
            indent: 30.0,
            endIndent: 30.0,
            height: 1,
            color: Colors.white24,
          );
        },
        physics: BouncingScrollPhysics(),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {},
            // splashFactory: InkRipple.splashFactory,
            child: Container(
                padding: EdgeInsets.all(16.0),
                child: Wrap(
                  children: <Widget>[
                    _posts[index].thumbnail == null
                        ? Icon(Icons.filter)
                        : Image.network(_posts[index].thumbnail),
                    Text(
                      _posts[index].title,
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    )
                  ],
                )),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // _initUser();
          String url = await _initUser();
          if (url != 'already logged in') {
            debugPrint('opening');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LoginScreen(
                        loginUri: url,
                        redirectUri: "https://www.reddit.com/r/android",
                        callback: (data) => {_authUser(data)})));
          } else {}
          // Add your onPressed code here!
        },
        child: Icon(Icons.navigation),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Post {
  String title;
  String author;
  String url;
  String permalink;
  int comments;
  int points;
  String id;
  bool self;
  String thumbnail;
}
