import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'flutter_camera_preview.dart';

class FutterCamera extends StatefulWidget {
  const FutterCamera({Key? key}) : super(key: key);

  @override
  State<FutterCamera> createState() => _FutterCameraState();
}

class _FutterCameraState extends State<FutterCamera> {
  XFile? photo;

  @override
  Widget build(BuildContext context) {
    void openCamera(CameraLensDirection direction) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlutterCameraPreview(
            cameraSide: direction,
            onFile: (file) {
              photo = file;
              Navigator.of(context).pop();
              setState(() {});
            },
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        body: photo != null
            ? SizedBox(
                width: double.maxFinite,
                height: double.maxFinite,
                child: Image.file(
                  File(photo!.path),
                  fit: BoxFit.cover,
                ),
              )
            : Container(),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => openCamera(CameraLensDirection.front),
              child: const Text('Front'),
            ),
            ElevatedButton(
              onPressed: () => openCamera(CameraLensDirection.back),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
