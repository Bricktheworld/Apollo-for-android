import 'dart:ui';

import 'package:flutter/material.dart';
import './dismissible.dart';

class PopupImageView extends StatefulWidget {
  final bool isShown;
  final media;
  final Function onDismiss;

  PopupImageView({Key key, this.isShown = false, this.media, this.onDismiss})
      : super(key: key);

  @override
  _PopupImageViewState createState() => _PopupImageViewState();
}

class _PopupImageViewState extends State<PopupImageView>
    with TickerProviderStateMixin {
  Animation<double> animationBlur;
  Animation<double> animationImage;
  AnimationController controller;
  AnimationController imageAnimationController;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    animationBlur = Tween<double>(begin: 0, end: 35).animate(controller)
      ..addListener(() {
        setState(() {});
      });
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isShown) {
      if (widget.media == null)
        throw Exception("u forgot to provide an image dummy");
      controller.forward();
      imageAnimationController.forward();
    } else {
      controller.reverse();
      imageAnimationController.reverse();
    }
    return Container(
      child: IgnorePointer(
        ignoring: !widget.isShown,
        child: DismissibleCustom(
          onDismissed: (direction, amount) {
            debugPrint("on dismiss");
            widget.onDismiss();
          },
          onMove: (double amount) {},
          dismissThresholds: {
            DismissDirection.endToStart: 0,
            DismissDirection.startToEnd: 0,
          },
          direction: DismissDirection.vertical,
          key: Key('random key i guess'),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: animationBlur.value, sigmaY: animationBlur.value),
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
        ),
      ),
    );
  }
}
