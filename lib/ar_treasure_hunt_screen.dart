import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:camera/camera.dart';
import 'hint_screen.dart';
import 'package:vector_math/vector_math_64.dart' as vector64;

class Artreasure extends StatefulWidget {
  const Artreasure({Key? key}) : super(key: key);

  @override
  State<Artreasure> createState() => _ArtreasureState();
}

class _ArtreasureState extends State<Artreasure> {
  late CameraController _cameraController;
  ArCoreController? augmentedRealityCoreController;
  bool isSphereTapped = false;
  ArCoreNode? sphereNode;

  final augmentedImages = {
    'image1': 'assets/a1.jpg',
    'image2': 'assets/a2.jpg',
  };
  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    // You may want to handle camera initialization errors here.
    if (mounted) {
      setState(() {
        // Make sure the widget is still mounted before updating the state.
      });
    }
  }
  @override
  void dispose() {
     _cameraController.dispose();
    augmentedRealityCoreController?.dispose();
    super.dispose();
  }

  augmentedRealityViewCreated(ArCoreController coreController) {
    augmentedRealityCoreController = coreController;
    augmentedRealityCoreController?.onNodeTap = onTapHandler;

    // Set up image tracking for your desired images
    augmentedRealityCoreController?.onTrackingImage = (arCoreAugmentedImage) {
      // Check if the detected image matches one of your desired images
      if (augmentedImages.containsKey(arCoreAugmentedImage.name)) {
        // Display the spheres at specific locations based on the detected image
        print("image recognized");
        Fluttertoast.showToast(msg: 'Image DETECTED');
        displaySphere(augmentedRealityCoreController!, arCoreAugmentedImage);
      }
    };
  }

  void onTapHandler(String spherenode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => hintScreen(),
      ),
    );
  }

  displaySphere(ArCoreController coreController, ArCoreAugmentedImage arCoreAugmentedImage) async {
    final ByteData textureBytes = await rootBundle.load('assets/gold.jpg');
    final materials = ArCoreMaterial(
      color: Colors.blue,
      textureBytes: textureBytes.buffer.asUint8List(),
    );

    final sphere = ArCoreSphere(
      materials: [materials],
      radius: 0.2, // Adjust the sphere size as needed
    );

    final translation = arCoreAugmentedImage.centerPose.translation;
    final sphereNode = ArCoreNode(
      name: 'spherenode',
      shape: sphere,
      position: vector64.Vector3(translation.x, translation.y, translation.z - 0.1), // Adjust z-position as needed
      rotation: vector64.Vector4(0, 0, 0, 1), // No rotation by default
    );
    
    coreController.addArCoreNode(sphereNode);
  }

  @override
  Widget build(BuildContext context) {
     if (_cameraController == null || !_cameraController.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(), // or any loading indicator
      );
    }

    return Scaffold( 
      appBar: AppBar(
        title: const Text("AR Treasure Hunt"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_cameraController)),
          Expanded(
            child: ArCoreView(
              onArCoreViewCreated: augmentedRealityViewCreated,
              enableTapRecognizer: true,
            ),
          ),
        ],
      ),
    );
  }
}  
