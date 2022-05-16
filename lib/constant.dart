// Counting pointers (number of user fingers on screen)

import 'package:flutter/material.dart';
import 'package:flutter_better_camera/camera.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

int pointers = 0;

double currentScale = 1.0;
double baseScale = 1.0;

void handleScaleStart(ScaleStartDetails details) {
  baseScale = currentScale;
}

// loading
bool saveLoading = false;
double savingProgress = 0.0;
bool isLoading = true;
bool isRecordingInProgress = false;

// flashmode
FlashMode? currentFlashMode;
bool onFlashClick = true;

//rear camera
bool isRearCameraSelected = true;

final resolutionPresets = ResolutionPreset.values;

ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

// zoom

double minAvailableExposureOffset = 0.0;
double maxAvailableExposureOffset = 0.0;
double minAvailableZoom = 1.0;
double maxAvailableZoom = 1.0;
double currentZoomLevel = 1.0;
double currentExposureOffset = 0.0;

final isDialOpen = ValueNotifier(false);

// Future<void> handleScaleUpdate(
//     ScaleUpdateDetails details, CameraController _cameraController) async {
//   // When there are not exactly two fingers on screen don't scale
//   if (pointers != 2) {
//     return;
//   }

//   currentScale =
//       (baseScale * details.scale).clamp(minAvailableZoom, maxAvailableZoom);

//   // await _cameraController.setZoomLevel(currentScale);
// }

class CustomTimeButton extends StatelessWidget {
  const CustomTimeButton({
    Key? key,
    required this.label,
    this.onPressed,
  }) : super(key: key);
  final String label;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.circle,
          color: Colors.white,
          size: 50,
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
                color: Colors.black, fontSize: 10, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
              primary: Colors.white,
              shape: CircleBorder(),
              side: BorderSide(color: Colors.black, width: 2)),
        )
      ],
    );
  }
}

void showInSnackBar(String message) {
  // ignore: deprecated_member_use
  scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
}

// timer
bool startPressed = true;
bool stopPressed = true;
bool resetPressed = true;

final dur = const Duration(seconds: 1);
