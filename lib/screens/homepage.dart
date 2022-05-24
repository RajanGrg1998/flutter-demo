import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_recorder_app/constant.dart';
import 'package:video_recorder_app/controller/clip_controller.dart';
import 'package:video_recorder_app/controller/lastclip_controller.dart';
import 'package:video_recorder_app/main.dart';
import 'package:video_recorder_app/screens/editor/demo.dart';
import 'package:video_recorder_app/screens/iso/ios_editclips_page.dart';
import 'package:video_recorder_app/screens/zoomablewidget.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({Key? key}) : super(key: key);

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

void logError(String code, String? message) {
  if (message != null) {
    print('Error: $code\nError Message: $message');
  } else {
    print('Error: $code');
  }
}

class _RecordingPageState extends State<RecordingPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  VideoPlayerController? videoController;

  String? videoPath;
  late VoidCallback videoPlayerListener;

  bool lastSecClicked = true;

  bool isChangeColor = false;

  List<File> allFiles = [];

  String stopTimeDisplay = "00:00:00";
  var swatch = Stopwatch();

  var extend = false;
  var rmicons = false;

  @override
  void initState() {
    super.initState();
    onNewCameraSelected(cameras[0]);
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized!) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  void resetCameraValues() async {
    currentZoomLevel = 1.0;
    currentExposureOffset = 0.0;
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : currentResolutionPreset,
      enableAudio: true,
    );

    _cameraController = cameraController;

    currentFlashMode = _cameraController!.value.flashMode;
    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        print('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await cameraController.prepareForVideoRecording();

      setState(() => isLoading = false);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var clipCon = Provider.of<ClipController>(context);
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return SafeArea(
        child: WillPopScope(
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: CupertinoColors.black,
              padding: EdgeInsetsDirectional.only(start: 5, end: 16),
              middle: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: isChangeColor == false
                          ? Colors.transparent
                          : Colors.red[400],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '$stopTimeDisplay',
                    style:
                        TextStyle(fontSize: 14, color: CupertinoColors.white),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              trailing: Text(
                '1080p',
                style: TextStyle(fontSize: 14, color: CupertinoColors.white),
              ),
              leading: CupertinoButton(
                onPressed: () {
                  onNewCameraSelected(
                    cameras[isRearCameraSelected ? 1 : 0],
                  );
                  setState(() {
                    isRearCameraSelected = !isRearCameraSelected;
                  });
                },
                child: Icon(
                  CupertinoIcons.camera_rotate,
                  size: 20,
                  color: CupertinoColors.white,
                ),
              ),
              // leading: Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     // Expanded(
              //     //   child: CupertinoButton(
              //     //     onPressed: () async {
              //     //       if (isRearCameraSelected) {
              //     //         setState(() {
              //     //           currentFlashMode =
              //     //               onFlashClick ? FlashMode.torch : FlashMode.off;
              //     //         });

              //     //         setState(() {
              //     //           onFlashClick = !onFlashClick;
              //     //         });

              //     //         await _cameraController!
              //     //             .setFlashMode(currentFlashMode!);
              //     //       }
              //     //     },
              //     //     child: Icon(
              //     //         onFlashClick
              //     //             ? CupertinoIcons.lightbulb_slash
              //     //             : CupertinoIcons.lightbulb,
              //     //         size: 20,
              //     //         color: onFlashClick
              //     //             ? CupertinoColors.white
              //     //             : CupertinoColors.systemYellow),
              //     //   ),
              //     // ),
              //     // SizedBox(width: 10),
              //     Expanded(
              //       child: CupertinoButton(
              //         onPressed: () {
              //           onNewCameraSelected(
              //             cameras[isRearCameraSelected ? 1 : 0],
              //           );
              //           setState(() {
              //             isRearCameraSelected = !isRearCameraSelected;
              //           });
              //         },
              //         child: Icon(
              //           CupertinoIcons.camera_rotate,
              //           size: 20,
              //           color: CupertinoColors.white,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ),
            key: scaffoldKey,
            backgroundColor: CupertinoColors.black,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    child: ZoomableWidget(
                      child: CameraPreview(_cameraController!),
                      onTapUp: (scaledPoint) {
                        // _cameraController!.setPointOfInterest(scaledPoint);
                      },
                      onZoom: (zoom) {
                        print('zoom');
                        if (zoom < 11) {
                          _cameraController!.zoom(zoom);
                        }
                      },
                    ),
                  ),
                  saveLoading
                      ? Align(
                          alignment: Alignment.center,
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: savingProgress,
                          ))
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 12.0, top: 8.0, left: 4),
                          child: SpeedDial(
                            overlayColor: Colors.transparent,
                            switchLabelPosition: true,
                            backgroundColor: Colors.black,
                            overlayOpacity: 0,
                            buttonSize: Size(50, 50),
                            openCloseDial: isDialOpen,
                            childrenButtonSize: Size(50, 50),
                            shape: StadiumBorder(
                                side:
                                    BorderSide(color: Colors.white, width: 4)),
                            elevation: 1.5,
                            child: Icon(
                              Icons.circle,
                              size: 50,
                              color: Colors.red,
                            ),
                            childMargin:
                                EdgeInsets.only(top: 5, bottom: 5, right: 5),
                            childPadding:
                                EdgeInsets.only(top: 5, bottom: 5, right: 5),
                            // icon: Icons.share,
                            children: [
                              SpeedDialChild(
                                label: isRecordingInProgress
                                    ? 'Resume Session'
                                    : 'Start Session',
                                labelStyle: TextStyle(color: Colors.black),
                                child: Icon(Icons.play_arrow_sharp),
                                onTap: () async {
                                  if (_cameraController!
                                      .value.isRecordingPaused) {
                                    await resumeVideoRecording();
                                    showInSnackBar('Session Resume');
                                  } else {
                                    onVideoRecordButtonPressed();

                                    // showInSnackBar('Session Started');
                                  }
                                },
                              ),
                              _cameraController!.value.isRecordingVideo!
                                  ? SpeedDialChild(
                                      label: 'Pause Session',
                                      child: Icon(Icons.pause_sharp),
                                      onTap: () async {
                                        if (!_cameraController!
                                            .value.isRecordingPaused) {
                                          await pauseVideoRecording();
                                        }
                                        showInSnackBar('Session Pause');
                                      },
                                    )
                                  : SpeedDialChild(),
                              _cameraController!.value.isRecordingVideo!
                                  ? SpeedDialChild(
                                      label: 'Stop Session',
                                      child: Icon(Icons.stop_sharp),
                                      onTap: () async {
                                        onStopButtonPressed();
                                        setState(() {
                                          isChangeColor = false;
                                        });
                                        resetWatch();
                                        if (videoPath == null) {
                                          return;
                                        }
                                        clipCon.addFullSession(videoPath!);

                                        print(
                                            'session: ${clipCon.fullSessionList}');
                                        if (clipCon
                                            .clippedSessionList.isEmpty) {
                                          return _showMyDialog(
                                              context, videoPath!);
                                        }
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  IOSEditClipPage(),
                                            ));

                                        // if (_cameraController!
                                        //     .value.isRecordingVideo!) {

                                        // }

                                        // Navigator.push(
                                        //     context,
                                        //     MaterialPageRoute(
                                        //       builder: (context) => DemoPreviewPage(
                                        //           filePath: videoPath!),
                                        //     ));
                                      })
                                  : SpeedDialChild(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 80, right: 25, top: 10),
                        child: Divider(
                          height: 126,
                          thickness: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(25, -70),
                      child: Text(
                        'Save Last',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(-15, -6),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomTimeButton(
                              label: ':10',
                              onPressed: () async {
                                if (_cameraController!
                                    .value.isRecordingVideo!) {
                                  stopVideoRecording();

                                  print('stop recording');
                                  clipCon.addFullSession(videoPath!);
                                  print(clipCon.fullSessionList.toString());
                                  VideoPlayerController controller =
                                      VideoPlayerController.file(
                                          File(videoPath!));
                                  await controller.initialize();
                                  double duration = controller
                                      .value.duration.inSeconds
                                      .toDouble();
                                  double last10Sec = (duration - 10.0);
                                  LastClipController().saveLastClipVideo(
                                      startValue: last10Sec.abs(),
                                      endValue: duration,
                                      onSave: (outcome) async {
                                        clipCon.clipedLastSecond(outcome);
                                        // clipCon.addTrimmedClipped(outcome);
                                        // await GallerySaver.saveVideo(outcome);
                                      },
                                      videoFile: File(videoPath!));
                                  onVideoRecordButtonPressed();
                                  print('start recording agian');
                                }
                              },
                            ),
                            CustomTimeButton(
                              label: ':30',
                              onPressed: () async {
                                if (_cameraController!
                                    .value.isRecordingVideo!) {
                                  stopVideoRecording();

                                  print('stop recording');
                                  clipCon.addFullSession(videoPath!);
                                  print(clipCon.fullSessionList.toString());
                                  VideoPlayerController controller =
                                      VideoPlayerController.file(
                                          File(videoPath!));
                                  await controller.initialize();
                                  double duration = controller
                                      .value.duration.inSeconds
                                      .toDouble();
                                  double last30Sec = (duration - 30.0);
                                  LastClipController().saveLastClipVideo(
                                      startValue: last30Sec.abs(),
                                      endValue: duration,
                                      onSave: (outcome) async {
                                        clipCon.clipedLastSecond(outcome);
                                        // clipCon.addTrimmedClipped(outcome);
                                        // await GallerySaver.saveVideo(outcome);
                                      },
                                      videoFile: File(videoPath!));
                                  onVideoRecordButtonPressed();
                                  print('start recording agian');
                                }
                              },
                            ),
                            CustomTimeButton(
                              label: '1:00',
                              onPressed: () async {
                                if (_cameraController!
                                    .value.isRecordingVideo!) {
                                  stopVideoRecording();

                                  print('stop recording');
                                  clipCon.addFullSession(videoPath!);
                                  print(clipCon.fullSessionList.toString());
                                  VideoPlayerController controller =
                                      VideoPlayerController.file(
                                          File(videoPath!));
                                  await controller.initialize();
                                  double duration = controller
                                      .value.duration.inSeconds
                                      .toDouble();
                                  double last60Sec = (duration - 60.0);
                                  LastClipController().saveLastClipVideo(
                                      startValue: last60Sec.abs(),
                                      endValue: duration,
                                      onSave: (outcome) async {
                                        clipCon.clipedLastSecond(outcome);
                                        // clipCon.addTrimmedClipped(outcome);
                                        // await GallerySaver.saveVideo(outcome);
                                      },
                                      videoFile: File(videoPath!));
                                  onVideoRecordButtonPressed();
                                  print('start recording agian');
                                }
                              },
                            ),
                            CustomTimeButton(
                              label: '3:00',
                              onPressed: () async {
                                if (_cameraController!
                                    .value.isRecordingVideo!) {
                                  stopVideoRecording();

                                  print('stop recording');
                                  clipCon.addFullSession(videoPath!);
                                  print(clipCon.fullSessionList.toString());
                                  VideoPlayerController controller =
                                      VideoPlayerController.file(
                                          File(videoPath!));
                                  await controller.initialize();
                                  double duration = controller
                                      .value.duration.inSeconds
                                      .toDouble();
                                  double last60Sec = (duration - 180.0);
                                  LastClipController().saveLastClipVideo(
                                      startValue: last60Sec.abs(),
                                      endValue: duration,
                                      onSave: (outcome) async {
                                        clipCon.clipedLastSecond(outcome);
                                        // clipCon.addTrimmedClipped(outcome);
                                        // await GallerySaver.saveVideo(outcome);
                                      },
                                      videoFile: File(videoPath!));
                                  onVideoRecordButtonPressed();
                                  print('start recording agian');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          onWillPop: () async {
            if (isDialOpen.value) {
              isDialOpen.value = false;
              return false;
            } else {
              return true;
            }
          },
        ),
      );
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    print('Error: ${e.code}\n${e.description}');
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String? filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String?> startVideoRecording() async {
    if (!_cameraController!.value.isInitialized!) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (_cameraController!.value.isRecordingVideo!) {
      // A recording is already started, do nothing.
      // await GallerySaver.saveVideo(filePath);
      return null;
    }

    try {
      videoPath = filePath;
      await _cameraController!.startVideoRecording(filePath);
      setState(() {
        isRecordingInProgress = true;
        isChangeColor = true;
      });
      startWatch();
      print('File: ' + filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

// stop recording

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      // showInSnackBar('Video recorded to: $videoPath');
    });
  }

  Future<void> stopVideoRecording() async {
    if (!_cameraController!.value.isRecordingVideo!) {
      return null;
    }

    try {
      setState(() {
        isRecordingInProgress = false;
      });
      await _cameraController!.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    // await _startVideoPlayer();
  }

// pause

  Future<void> pauseVideoRecording() async {
    if (!_cameraController!.value.isRecordingVideo!) {
      return null;
    }

    try {
      await _cameraController!.pauseVideoRecording();
      pasueWatch();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!_cameraController!.value.isRecordingVideo!) {
      return null;
    }

    try {
      await _cameraController!.resumeVideoRecording();
      startWatch();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  // for timer

  void startTimer() {
    Timer(dur, keepRunning);
  }

  void keepRunning() {
    if (swatch.isRunning) {
      startTimer();
    }
    setState(() {
      stopTimeDisplay = swatch.elapsed.inHours.toString().padLeft(2, '0') +
          ':' +
          (swatch.elapsed.inMinutes % 60).toString().padLeft(2, '0') +
          ':' +
          (swatch.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    });
  }

  void resetWatch() {
    setState(() {
      startPressed = true;
      resetPressed = true;
    });
    swatch.stop();
    swatch.reset();
    stopTimeDisplay = "00:00:00";
  }

  void startWatch() {
    setState(() {
      stopPressed = false;
      startPressed = false;
    });
    swatch.start();
    startTimer();
  }

  void pasueWatch() {
    setState(() {
      stopPressed = true;
      resetPressed = false;
    });
    swatch.stop();
  }

  // To store the retrieved files

  Future<void> _showMyDialog(BuildContext context, String path) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Recorder'),
          content: Text('Do you want to Save Recorded Video'),
          actions: <Widget>[
            CupertinoDialogAction(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            CupertinoDialogAction(
              child: const Text('Yes'),
              onPressed: () async {
                EasyLoading.show(status: 'Session Saving...');
                await GallerySaver.saveVideo(path);
                showInSnackBar('Recording saved to gallery');
                EasyLoading.showSuccess('Session saved to Gallery');
                EasyLoading.dismiss();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
