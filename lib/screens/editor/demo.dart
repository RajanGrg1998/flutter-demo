import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_recorder_app/controller/clip_controller.dart';

class DemoDa extends StatelessWidget {
  const DemoDa({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var clipCon = Provider.of<ClipController>(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: clipCon.fullSessionList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(clipCon.fullSessionList[index]),
          );
        },
      ),
    );
  }
}
