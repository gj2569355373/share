import 'dart:async';

import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class MaterialControlMy extends StatefulWidget {
  const MaterialControlMy({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MaterialControlsState();
  }
}

class MaterialControlsState extends State<MaterialControlMy>
    with SingleTickerProviderStateMixin {
  final iconColor =Colors.white;
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController chewieController;
  AnimationController playPauseIconAnimationController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }
    // print("刷新");
    return  GestureDetector(//快进手势可以在此子方法监听处理
//        onVerticalDragDown: (details) {
//          print("垂直onVerticalDragDown---$details");
//        },
//        onVerticalDragStart: (details) {
//          print("垂直onVerticalDragStart---$details");
//        },
//        onVerticalDragUpdate: (details) {
//          print("垂直onVerticalDragUpdate---$details");
//        },
//        onVerticalDragEnd: (details) {
//          print("垂直onVerticalDragEnd---$details");
//        },
//        onVerticalDragCancel: () {
//          print("垂直onVerticalDragCancel");
//        },
//
//        onHorizontalDragDown: (details) {
//          print("横向onHorizontalDragDown---$details");
//        },
//        onHorizontalDragStart: (details) {
//
//          print("横向onHorizontalDragStart---$details");
//        },
//        onHorizontalDragUpdate: (DragUpdateDetails details) {
//          print("横向onHorizontalDragUpdate---$details");
//        },
//        onHorizontalDragEnd: (details) {
//          print("横向onHorizontalDragEnd---$details");
//        },
//        onHorizontalDragCancel: () {
//          print("横向onHorizontalDragCancel");
//        },
//        onSecondaryTapUp:(details){
//          print("onSecondaryTapUp---$details");
//        },
//        onSecondaryTapDown:(details){
//          print("onSecondaryTapDown---$details");
//        },
//        onSecondaryTapCancel:(){
//          print("onSecondaryTapCancel---");
//        },
//        onTapCancel:(){
//          print("onTapCancel---");
//        },
//        onTapDown: (details) {
//          print("onTapDown---$details");
//        },
//        onTapUp: (details) {
//          print("onTapUp---$details");
//        },
        onDoubleTap: () => _playPause(),
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              AnimatedOpacity(
                opacity: _hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child:
                  Container(
                    height: barHeight,
                    color: Colors.black26,
                    child:
                      Row(mainAxisAlignment: MainAxisAlignment.end ,children: [
                        if (chewieController.allowMuting) _buildMuteButton(controller),
                        if (chewieController.allowPlaybackSpeedChanging)
                          _buildSpeedButton(controller),
                      ],),
                  ),
              ),
              if (_latestValue != null &&
                      !_latestValue.isPlaying &&
                      _latestValue.duration == null ||
                  _latestValue.isBuffering)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildHitArea(),
              _buildBottomBar(context),
            ],
          ),
        ),
      );

  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    playPauseIconAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Colors.black26,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            if (chewieController.isLive)
              const Expanded(child: Text('LIVE'))
            else
              _buildPositionLeft(),
            if (chewieController.isLive)
              const SizedBox()
            else
              _buildProgressBar(),
            if (chewieController.isLive)
              const Expanded(child: Text('LIVE'))
            else
              _buildPositionRight(),
            if (chewieController.allowFullScreen) _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else {
              _cancelAndRestartTimer();
            }
          } else {
//            _playPause();
//            setState(() {
//              _hideStuff = true;
//            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Offstage(
              offstage: !(_latestValue != null && !_latestValue.isPlaying && !_dragging),
              child: Container(
                  width: 60,height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: InkWell(
                      child: isFinished
                          ? const Icon(Icons.replay, size: 30.0,color: Colors.white)
                          : InkWell(
                        onTap: (){_playPause();},
                        child: Icon(Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
//                        AnimatedIcon(
//                          icon: AnimatedIcons.play_pause,
//                          progress: playPauseIconAnimationController,
//                          size: 32.0,),
                      onTap: () {
                        _playPause();
                      })
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();

        final chosenSpeed = await showModalBottomSheet<double>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) =>
              Container(height: MediaQuery.of(context).size.width*(chewieController.isFullScreen?0.25:0.5),child: _PlaybackSpeedDialog(
                speeds: chewieController.playbackSpeeds,
                selected: _latestValue.playbackSpeed,
              ),),
        );

        if (chosenSpeed != null) {
          controller.setPlaybackSpeed(chosenSpeed);
        }

        if (_latestValue.isPlaying) {
          _startHideTimer();
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: Icon(Icons.speed,color: iconColor,),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: Icon(
              (_latestValue != null && _latestValue.volume > 0)
                  ? Icons.volume_up
                  : Icons.volume_off,color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,color: iconColor
        ),
      ),
    );
  }

  Widget _buildPositionRight() {
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(right: 0.0),
      child: Text(formatDuration(duration),
        style:  TextStyle(
            fontSize: 14.0,
            color: iconColor
        ),
      ),
    );
  }
  Widget _buildPositionLeft() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Text(formatDuration(position),
        style:  TextStyle(
          fontSize: 14.0,
          color: iconColor
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    print("_cancelAndRestartTimer");
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;
      if(chewieController.isFullScreen)
        Get.back();
      else
        chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }
  notifyListeners(){
    setState(() {});
  }
  void _playPause() {
    bool isFinished;
    if (_latestValue.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    } else {
      isFinished = false;
    }

    setState(() {
      if (controller.value.isPlaying) {
        playPauseIconAnimationController.reverse();
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
        Wakelock.disable();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
            playPauseIconAnimationController.forward();
          });
        } else {
          if (isFinished) {
            controller.seekTo(const Duration());
          }
          playPauseIconAnimationController.forward();
          controller.play();
          Wakelock.enable();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 14.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: iconColor,
                  backgroundColor: iconColor,)
        ),
      ),
    );
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    Key key,
    @required List<double> speeds,
    @required double selected,
  })  : _speeds = speeds,
        _selected = selected,
        super(key: key);

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemBuilder: (context, index) {
        final _speed = _speeds[index];
        return ListTile(
          dense: true,
          title: Row(
            children: [
              if (_speed == _selected)
                Icon(
                  Icons.check,
                  size: 20.0,
                  color: selectedColor,
                )
              else
                Container(width: 20.0),
              const SizedBox(width: 16.0),
              Text(_speed.toString()),
            ],
          ),
          selected: _speed == _selected,
          onTap: () {
            Navigator.of(context).pop(_speed);
          },
        );
      },
      itemCount: _speeds.length,
    );
  }
}
