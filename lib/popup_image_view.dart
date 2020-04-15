import 'dart:ui';

import 'package:flutter/material.dart';
import './dismissible.dart';

class PopupImageView extends StatefulWidget {
  final media;

  PopupImageView({Key key, this.media}) : super(key: key);

  @override
  _PopupImageViewState createState() => _PopupImageViewState();
}

class _PopupImageViewState extends State<PopupImageView>
    with TickerProviderStateMixin {
  Animation<double> animationImage;
  AnimationController imageAnimationController;

  @override
  void initState() {
    super.initState();
    imageAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    animationImage =
        Tween<double>(begin: 0, end: 1).animate(new CurvedAnimation(
            curve: Curves.bounceOut,
            // reverseCurve: Curves.elasticOut,
            parent: imageAnimationController))
          ..addListener(() {
            setState(() {});
          });

    imageAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DismissibleCustom(
        onDismissed: (direction, amount) {
          debugPrint("on dismiss");
          Navigator.pop(context);
        },
        onMove: (double amount) {
          // debugPrint(amount.toString());
        },
        dismissThresholds: {
          DismissDirection.endToStart: 0,
          DismissDirection.startToEnd: 0,
        },
        direction: DismissDirection.vertical,
        key: Key('random key i guess'),
        child: Container(
          alignment: AlignmentDirectional.center,
          decoration: new BoxDecoration(
            color: Colors.white.withOpacity(0.0),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    imageAnimationController.value),
            child: Container(
              // width: MediaQuery.of(context).size.width *
              //     imageAnimationController.value,
              child: widget.media,
            ),
          ),
        ),
      ),
    );
  }
}
