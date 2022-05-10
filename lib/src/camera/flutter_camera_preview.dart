import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FlutterCameraPreview extends StatefulWidget {
  final Function(XFile? file)? onFile;
  final CameraLensDirection cameraSide;
  const FlutterCameraPreview({
    Key? key,
    this.onFile,
    required this.cameraSide,
  }) : super(key: key);

  @override
  _FlutterCameraPreviewState createState() => _FlutterCameraPreviewState();
}

class _FlutterCameraPreviewState extends State<FlutterCameraPreview>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _zoomModeControlRowAnimationController;
  late Animation<double> _zoomModeControlRowAnimation;
  double _zoom = 0.0;

  @override
  void initState() {
    super.initState();

    availableCameras().then((cameras) {
      final camera = cameras
          .where((element) => element.lensDirection == widget.cameraSide)
          .first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller.initialize();

      if (mounted) setState(() {});
    });

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    _zoomModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _zoomModeControlRowAnimation = CurvedAnimation(
      parent: _zoomModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flashModeControlRowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        key: _scaffoldKey,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: [
                  Expanded(child: CameraPreview(_controller)),
                  SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_on),
                          color: Colors.blue,
                          onPressed: onFlashModeButtonPressed,
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: () async {
                            final file = await _controller.takePicture();
                            widget.onFile!(file);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          color: Colors.blue,
                          onPressed: onZoomModeButtonPressed,
                        ),
                      ],
                    ),
                  ),
                  _flashModeControlRowWidget(),
                  _zoomModeControlRowWidget(),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: const Icon(Icons.flash_off),
              color: _controller.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: () => onSetFlashModeButtonPressed(FlashMode.off),
            ),
            IconButton(
              icon: const Icon(Icons.flash_auto),
              color: _controller.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: () => onSetFlashModeButtonPressed(FlashMode.auto),
            ),
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: _controller.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: () => onSetFlashModeButtonPressed(FlashMode.always),
            ),
            IconButton(
              icon: const Icon(Icons.highlight),
              color: _controller.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.blue,
              onPressed: () => onSetFlashModeButtonPressed(FlashMode.torch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _zoomModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.zoom_out),
                      Slider(
                        activeColor: Colors.red,
                        value: _zoom,
                        onChanged: (value) {
                          value = value * 10;
                          if (value <= 8.0 && value >= 1.0) {
                            _controller.setZoomLevel(value);
                            setState(() => _zoom = value / 10);
                          }
                        },
                      ),
                      const Icon(Icons.zoom_in),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _zoomModeControlRowAnimationController.reverse();
    }
  }

  void onZoomModeButtonPressed() {
    if (_zoomModeControlRowAnimationController.value == 1) {
      _zoomModeControlRowAnimationController.reverse();
    } else {
      _zoomModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    try {
      await _controller.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }
}
