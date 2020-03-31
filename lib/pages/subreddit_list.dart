import 'package:apollo/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import '../AuthModel.dart';
import '../subreddit_post_view.dart';
import 'package:transparent_image/transparent_image.dart';

class SubredditListView extends StatefulWidget {
  final AuthModel model;
  final Function preloadSubredditPosts;

  const SubredditListView({Key key, this.model, this.preloadSubredditPosts})
      : super(key: key);

  @override
  _SubredditListViewState createState() => _SubredditListViewState();
}

class _SubredditListViewState extends State<SubredditListView> {
  List<Subreddit> subreddits = <Subreddit>[];

  @override
  void initState() {
    super.initState();
    widget.model.login(context, _fetchSubreddits);
  }

  _fetchSubreddits() async {
    subreddits = <Subreddit>[];
    debugPrint('fetching subreddits');
    Stream<Subreddit> stream = widget.model.reddit.user.subreddits();
    await for (Subreddit s in stream) {
      subreddits.add(s);
      subreddits.sort((Subreddit a, Subreddit b) =>
          a.displayName.toString()[0].compareTo(b.displayName.toString()[0]));
      await widget.preloadSubredditPosts(s);
      setState(() {});
      debugPrint(subreddits.length.toString());
    }
    // .listen((Subreddit data) async {
    //   subreddits.add(data);
    //   subreddits.sort((Subreddit a, Subreddit b) =>
    //       a.displayName.toString()[0].compareTo(b.displayName.toString()[0]));
    //   // await widget.preloadSubredditPosts(data);
    //   setState(() {});
    //   debugPrint(subreddits.length.toString());
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: CustomAppBar(title: 'Subreddits'),
      body: _buildList(),
    );
  }

  _goToSubreddit(Subreddit sub) {}

  _buildList() {
    return Scaffold(
        floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              onPressed: () async {
                _fetchSubreddits();
              },
              child: Icon(Icons.refresh),
              backgroundColor: Theme.of(context).secondaryHeaderColor,
            )),
        backgroundColor: Theme.of(context).backgroundColor,
        body: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: subreddits.length,
            itemBuilder: (BuildContext context, int index) {
              Subreddit sub = subreddits[index];
              Widget icon;
              if (sub.iconImage.toString() != "") {
                icon = Container(
                    width: 30,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0),
                        child: FadeInImage.memoryNetwork(
                          image: sub.iconImage.toString(),
                          placeholder: kTransparentImage,
                        )));
              } else {
                icon = Icon(
                  Icons.image,
                  color: Theme.of(context).accentColor,
                );
              }
              return Material(
                  color: Theme.of(context).primaryColor,
                  child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SubredditPostView(
                                    model: widget.model, sub: sub)));
                      },
                      child: ListTile(
                        leading: icon,
                        title: Text(sub.displayName,
                            style: TextStyle(color: Colors.white)),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Theme.of(context).accentColor),
                      )));
            }));
  }
}