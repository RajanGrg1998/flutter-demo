import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:video_recorder_app/controller/clip_controller.dart';
import 'package:video_recorder_app/helpers/trimmer/src/trim_editor.dart';
import 'package:video_recorder_app/helpers/trimmer/src/trimmer.dart';
import 'package:video_recorder_app/screens/editor/videoeditorpage.dart';
import 'package:video_recorder_app/screens/homepage.dart';

class IOSEditClipPage extends StatelessWidget {
  const IOSEditClipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var clipCon = Provider.of<ClipController>(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.zero,
        leading:
            clipCon.isMultiSelectionEnabled && clipCon.selectedItem.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text('Cancel'),
                    onPressed: () {
                      clipCon.selectedItem.clear();
                      clipCon.isMultiSelectionValue(false);
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {
                          _showMyDialog(context);
                        },
                        child: Icon(
                          CupertinoIcons.back,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Edit Clips',
                        style: TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            clipCon.isMultiSelectionEnabled
                ? Visibility(
                    visible: clipCon.selectedItem.isNotEmpty,
                    child: CupertinoButton(
                      padding: EdgeInsets.only(right: 15),
                      child: Text('Delete Clips'),
                      onPressed: () {
                        clipCon.removeClip();
                      },
                    ),
                  )
                : Container(),
            // Visibility(
            //     //visible: selectedItem.isNotEmpty,
            //     child: IconButton(
            //   icon: Icon(Icons.delete),
            //   onPressed: () {
            //     // selectedItem.forEach((nature) {
            //     //   natureList.remove(nature);
            //     // });
            //     // selectedItem.clear();
            //     // setState(() {});
            //   },
            // )),
            clipCon.timmedSessionList.isNotEmpty
                ? Visibility(
                    visible: clipCon.isMultiSelectionEnabled == false,
                    child: CupertinoButton(
                      padding: EdgeInsets.only(right: 15),
                      child: Text('Merge'),
                      onPressed: () {
                        clipCon.mergeRequest();
                      },
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        // trailing: clipCon.timmedSessionList.isNotEmpty
        // ? CupertinoButton(
        //     padding: EdgeInsets.only(right: 15),
        //     child: Text('Merge'),
        //     onPressed: () {
        //       clipCon.mergeRequest();
        //     },
        //   )
        //     : null,
      ),
      child: ListView.builder(
        itemCount: clipCon.clippedSessionList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSliders(
                customSlidersPath: clipCon.clippedSessionList[index]),
          );
        },
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Save Recorded Sessions'),
          content: Text('Do you want to save full recorded session'),
          actions: <Widget>[
            CupertinoDialogAction(
                child: const Text('No'),
                onPressed: () {
                  Provider.of<ClipController>(context, listen: false)
                      .onFinished();
                  Navigator.pop(context);
                  Navigator.pop(context);
                }),
            CupertinoDialogAction(
              child: const Text('Yes'),
              onPressed: () async {
                Provider.of<ClipController>(context, listen: false)
                    .mergeFullSessisionRequest()
                    .then((_) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class CustomSliders extends StatefulWidget {
  const CustomSliders({Key? key, required this.customSlidersPath})
      : super(key: key);
  final String customSlidersPath;

  @override
  State<CustomSliders> createState() => _CustomSlidersState();
}

class _CustomSlidersState extends State<CustomSliders> {
  final Trimmer _trimmer = Trimmer();
  Timer? _timer;

  @override
  void initState() {
    _loadVideo();
    super.initState();
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
  }

  Future<void> _loadVideo() async {
    await _trimmer.loadVideo(videoFile: File(widget.customSlidersPath));
  }

  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  // Future<void> _remove(BuildContext context, String path) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: true, // user must tap button!
  //     builder: (BuildContext context) {
  //       return CupertinoAlertDialog(
  //         title: const Text('Recorder'),
  //         content: Text('Do you want to Save Recorded Video'),
  //         actions: <Widget>[
  //           CupertinoDialogAction(
  //               child: const Text('No'),
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               }),
  //           CupertinoDialogAction(
  //             child: const Text('Yes'),
  //             onPressed: () async {
  //               Provider.of<ClipController>(context, listen: false)
  //                   .remove(path);
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    var clipCon = Provider.of<ClipController>(context);
    return GestureDetector(
      onLongPress: () {
        clipCon.isMultiSelectionValue(true);
        clipCon.doMultiSelection(widget.customSlidersPath);
      },
      onTap: clipCon.isMultiSelectionEnabled
          ? () {
              clipCon.doMultiSelection(widget.customSlidersPath);
            }
          : () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => VideoEditor(
                    file: File(widget.customSlidersPath),
                  ),
                ),
              );
            },
      child: Stack(
        children: [
          TrimEditor(
            trimmer: _trimmer,
            circlePaintColor: Colors.transparent,
            borderPaintColor: Colors.transparent,
            viewerHeight: 50.0,
            showDuration: false,
            thumbnailQuality: 25,
            viewerWidth: MediaQuery.of(context).size.width,
            maxVideoLength: const Duration(hours: 10),
            onChangeStart: (value) {},
            onChangeEnd: (value) {},
            onChangePlaybackState: (value) {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 10, right: 5),
            child: Align(
              alignment: Alignment.centerRight,
              child: Visibility(
                visible: clipCon.isMultiSelectionEnabled &&
                    clipCon.selectedItem.isNotEmpty,
                child: Icon(
                  clipCon.selectedItem.contains(widget.customSlidersPath)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
