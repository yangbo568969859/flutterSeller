import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seller/style/gaps.dart';
import 'package:seller/utils/route_util.dart';
import 'package:seller/utils/toast.dart';


class AddingButtonPage extends StatefulWidget {
    @override
    _AddingButtonPageState createState() => _AddingButtonPageState();
}

class _AddingButtonPageState extends State<AddingButtonPage> with TickerProviderStateMixin {
    /// Boolean to prevent duplicate pop.
    bool popping = false;

    /// Animation.
    int _animateDuration = 300;
    double _backdropFilterSize = 0.0;
    double _popButtonRotateAngle = 0.0;
    Animation<double> _backDropFilterAnimation;
    AnimationController _backDropFilterController;
    Animation<double> _popButtonAnimation;
    AnimationController _popButtonController;
    List<double> _itemOffset;
    List<Animation<double>> _itemAnimations;
    List<CurvedAnimation> _itemCurveAnimations;
    List<AnimationController> _itemAnimateControllers;
    List<double> _itemOpacity;
    List<Animation<double>> _itemOpacityAnimations;
    List<CurvedAnimation> _itemOpacityCurveAnimations;
    List<AnimationController> _itemOpacityAnimateControllers;

    List<String> itemTitles = ["扫码添加", "添加商品"];
    List<String> itemIcons = ["icon_after-sale", "icon_pay-success"];
    List<Color> itemColors = [Colors.orange, Colors.teal];
    List<Function> itemOnTap = [
        (context) { Navigator.pop(context);RouteUtil.routeToScanPage(context); },
        (context) async {
          // Navigator.pop(context);
          Map<PermissionGroup, PermissionStatus>permissions = await PermissionHandler().requestPermissions([
            PermissionGroup.camera,
          ]);
          print(permissions);
          if (permissions[PermissionGroup.camera] == PermissionStatus.granted) {
            Navigator.pop(context);
            RouteUtil.routeToGoodsEditPage(context);
          } else {
            MyToast.show('没有拍摄的权限');
          }
        },
    ];

    @override
    void initState() {
        initItemsAnimation();
        SchedulerBinding.instance.addPostFrameCallback((_) => backDropFilterAnimate(context, true));
        super.initState();
    }

    @override
    void dispose() {
        _backDropFilterController?.dispose();
        _popButtonController?.dispose();
        _itemAnimateControllers?.forEach((controller) { controller?.dispose(); });
        _itemOpacityAnimateControllers?.forEach((controller) { controller?.dispose(); });
        super.dispose();
    }

    void initItemsAnimation() {
        _itemOffset = <double>[for (int i=0; i<itemTitles.length; i++) 0.0];
        _itemAnimations = List<Animation<double>>(itemTitles.length);
        _itemCurveAnimations = List<CurvedAnimation>(itemTitles.length);
        _itemAnimateControllers = List<AnimationController>(itemTitles.length);
        _itemOpacity = <double>[for (int i=0; i<itemTitles.length; i++) 0.01];
        _itemOpacityAnimations = List<Animation<double>>(itemTitles.length);
        _itemOpacityCurveAnimations = List<CurvedAnimation>(itemTitles.length);
        _itemOpacityAnimateControllers = List<AnimationController>(itemTitles.length);

        for (int i = 0; i < itemTitles.length; i++) {
            _itemAnimateControllers[i] = AnimationController(
                duration: Duration(milliseconds: _animateDuration),
                vsync: this,
            );
            _itemCurveAnimations[i] = CurvedAnimation(
                parent: _itemAnimateControllers[i],
                curve: Curves.ease,
            );
            _itemAnimations[i] = Tween(
                begin: -20.0,
                end: 0.0,
            ).animate(_itemCurveAnimations[i])
                ..addListener(() {
                    setState(() {
                        _itemOffset[i] = _itemAnimations[i].value;
                    });
                });

            _itemOpacityAnimateControllers[i] = AnimationController(
                duration: Duration(milliseconds: _animateDuration),
                vsync: this,
            );
            _itemOpacityCurveAnimations[i] = CurvedAnimation(
                parent: _itemOpacityAnimateControllers[i],
                curve: Curves.linear,
            );
            _itemOpacityAnimations[i] = Tween(
                begin: 0.0,
                end: 1.0,
            ).animate(_itemOpacityCurveAnimations[i])
                ..addListener(() {
                    setState(() {
                        _itemOpacity[i] = _itemOpacityAnimations[i].value;
                    });
                });
        }
    }
    
    void itemsAnimate(bool forward) {
        for (int i = 0; i < _itemAnimateControllers.length; i++) {
            Future.delayed(Duration(milliseconds: 50 * i), () {
                if (forward) {
                    _itemAnimateControllers[i]?.forward();
                    _itemOpacityAnimateControllers[i]?.forward();
                } else {
                    _itemAnimateControllers[i]?.reverse();
                    _itemOpacityAnimateControllers[i]?.reverse();
                }
            });
        }
    }
    
    void popButtonAnimate(context, bool forward) {
        if (!forward) _popButtonController?.stop();
        final rotateDegree = 45 * (math.pi / 180) * 3;

        _popButtonController = AnimationController(
            duration: Duration(milliseconds: _animateDuration),
            vsync: this,
        );
        Animation _popButtonCurve = CurvedAnimation(
            parent: _popButtonController,
            curve: Curves.linear,
        );
        _popButtonAnimation = Tween(
            begin: forward ? 0.0 : _popButtonRotateAngle,
            end: forward ? rotateDegree : 0.0,
        ).animate(_popButtonCurve)
            ..addListener(() {
                setState(() {
                    _popButtonRotateAngle = _popButtonAnimation.value;
                });
            });
        _popButtonController.forward();
    }

    void backDropFilterAnimate(BuildContext context, bool forward) async {
        final Size s = MediaQuery.of(context).size;
        if (!forward) _backDropFilterController?.stop();
        popButtonAnimate(context, forward);

        _backDropFilterController = AnimationController(
            duration: Duration(milliseconds: _animateDuration),
            vsync: this,
        );
        Animation _backDropFilterCurve = CurvedAnimation(
            parent: _backDropFilterController,
            curve: forward ? Curves.easeInOut : Curves.easeIn,
        );
        _backDropFilterAnimation = Tween(
            begin: forward ? 0.0 : _backdropFilterSize,
            end: forward ? pythagoreanTheorem(s.width, s.height) * 2 : 0.0,
        ).animate(_backDropFilterCurve)
            ..addListener(() {
                setState(() {
                    _backdropFilterSize = _backDropFilterAnimation.value;
                });
            });
        _backDropFilterController.forward();
        if (forward) {
            Future.delayed(
                Duration(milliseconds: _animateDuration ~/ 2),
                        () { itemsAnimate(true); },
            );
        } else {
            itemsAnimate(false);
        }
    }

    double pythagoreanTheorem(double short, double long) {
        return math.sqrt(math.pow(short, 2) + math.pow(long, 2));
    }

    Widget popButton() {
        return Center(
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                    width: 64.4,
                    height: 64.4,
                    child: Transform.rotate(
                        angle: _popButtonRotateAngle,
                        child: Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 32.0,
                        ),
                    ),
                ),
                onTap: willPop,
            ),
        );
    }

    Widget wrapper(context, {Widget child}) {
        final Size s = MediaQuery.of(context).size;
        final double topOverflow = pythagoreanTheorem(s.width, s.height) - s.height;
        final double horizontalOverflow = pythagoreanTheorem(s.width, s.height) - s.width;

        return Stack(
            overflow: Overflow.visible,
            children: <Widget>[
                Positioned(
                    left: - horizontalOverflow,
                    right: - horizontalOverflow,
                    top: - topOverflow,
                    bottom: - pythagoreanTheorem(s.width, s.height),
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: willPop,
                        child: Center(
                            child: SizedBox(
                                width: _backdropFilterSize,
                                height: _backdropFilterSize,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(s.height * 2),
                                    child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                        child: Text(" ")
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
                Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                        margin: EdgeInsets.only(top: topOverflow, bottom: 64.4),
                        width: s.width,
                        height: s.height,
                        constraints: BoxConstraints(
                            maxWidth: s.width,
                            maxHeight: s.height,
                        ),
                        child: child ?? SizedBox(),
                    ),
                ),
                // Container(
                //   child: Text('1212'),
                // ),
                Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: 0.0,
                    child: popButton(),
                ),
            ],
        );
    }

    Widget item(BuildContext context, int index) {
      return Stack(
          overflow: Overflow.visible,
          children: <Widget>[
              Positioned(
                  left: 0.0, right: 0.0,
                  top: _itemOffset[index],
                  child: Opacity(
                      opacity: _itemOpacity[index],
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                        color: itemColors[index],
                                        shape: BoxShape.circle,
                                    ),
                                    child: Image.asset('assets/images/icon/${itemIcons[index]}.png', width: 30, height: 30),
                                  ),
                                  Gaps.vGap10,
                                  Text(
                                      itemTitles[index],
                                      style: Theme.of(context).textTheme.body1.copyWith(
                                          fontSize: 14.0,
                                      ),
                                  ),
                              ],
                          ),
                          onTap: () {
                              itemOnTap[index](context);
                          },
                      ),
                  ),
              ),
          ],
      );
    }

    Future<bool> willPop() async {
        backDropFilterAnimate(context, false);
        if (!popping) {
            popping = true;
            await Future.delayed(Duration(milliseconds: _animateDuration), () {
                Navigator.of(context).pop();
            });
        }
        return null;
    }

    @override
    Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: willPop,
        child: wrapper(context, child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: <Widget>[
                  for (int i = 0; i < itemTitles.length; i++)
                      item(context, i),
              ],
            ),
          ],
        )),
      );
    }
}

