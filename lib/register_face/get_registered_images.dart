import 'dart:io';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../ML/Recognition.dart';
import '../ML/Recognizer.dart';

class RegisteredImages extends StatefulWidget {
  const RegisteredImages({super.key});

  @override
  State<RegisteredImages> createState() => _RegisteredImagesState();
}

class _RegisteredImagesState extends State<RegisteredImages> {
  List<FileSystemEntity> items = []; List<FileSystemEntity> second = [];  bool isImage = false;
  late Recognizer _recognizer;
  late var faceDetector;
  @override
  void initState() {
    // TODO: implement initState
    //TODO initalize face recognizer
    _recognizer = Recognizer();
    final options = FaceDetectorOptions(
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false);

    //TODO initalize face detector
    faceDetector = FaceDetector(options: options);
    _imgFromCamera();
    super.initState();
  }

  _imgFromCamera() async {
    var  directory;
    if(Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }
    _listFiles(path: Platform.isAndroid?'/storage/emulated/0/': directory.path, image: false);
    return;

  }

  Future<void> _listFiles({required String path, bool image = false}) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      var files = directory.listSync();
      print('files detected ${files.length}');

      if (image) {
        List<FileSystemEntity> imageList =
        files.where((e) => _isImageFile(e.path) && !(e.path.contains(".trashed"))).toList();
        List<FileSystemEntity> data = [];
        List<FileSystemEntity> dataNot = [];
        for (int i = 0; i < imageList.length; i++) {
          if (await doFaceDetectionFilter(imageList[i].path)) {
            data.add(imageList[i]);
          } else {
            dataNot.add(imageList[i]);
          }
        }

      items = data; second =  dataNot ;  isImage = image;
      } else {
        items = files; second =  [] ;  isImage = image;

      }
      setState(() {

      });
    } else {
      throw Exception("Directory does not exist");
    }
  }

  Future<bool> doFaceDetectionFilter(String path) async {
    // faces.clear();

    //TODO remove rotation of camera images
    // _image = await removeRotation(File(path));

    //TODO passing input to face detector and getting detected faces
    final inputImage = InputImage.fromFile(File(path));
   List<Face> faces = await faceDetector.processImage(inputImage);

    //TODO call the method to perform face recognition on detected faces
    return await performFaceRecognitionFilter(faces, File(path));
  }

  Future<bool> performFaceRecognitionFilter(List<Face> faces, File imge) async {
   var image = await imge.readAsBytes();
    var decimage = await decodeImageFromList(image);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      num left = faceRect.left < 0 ? 0 : faceRect.left;
      num top = faceRect.top < 0 ? 0 : faceRect.top;
      num right =
      faceRect.right > decimage.width ? decimage.width - 1 : faceRect.right;
      num bottom =
      faceRect.bottom > decimage.height ? decimage.height - 1 : faceRect.bottom;
      num width = right - left;
      num height = bottom - top;

      //TODO crop face
      File cropedFace = await FlutterNativeImage.cropImage(
          imge!.path, left.toInt(), top.toInt(), width.toInt(), height.toInt());
      final bytes = await File(cropedFace!.path).readAsBytes();
      final img.Image? faceImg = img.decodeImage(bytes);
      Recognition recognition =
      _recognizer.recognize(faceImg!, face.boundingBox);

      if (recognition.distance > 1) {
        recognition.name = "Unknown";
        return false;
      }
      // recognitions.add(recognition);
      return true;
    }
    return false;
  }

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container(

      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select an Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          items.isEmpty
              ? Text("No Item")
              : Expanded(
            child: isImage
                ? SizedBox(

              child: Column(
                children: [
                  Text("Filtered"),
                  items.isEmpty
                      ? Text("No Item")
                      : Expanded(
                    child: GridView.builder(
                        itemCount: items.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4),
                        itemBuilder: (context, index) =>
                            Image.file(
                              File(items[index].path),
                              height: 80,
                              width: 80,
                            )),
                  ),
                  Text("Un Filtered"),
                  second.isEmpty
                      ? Text("No Item")
                      : Expanded(
                    child: GridView.builder(
                        itemCount: second.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4),
                        itemBuilder: (context, index) =>
                            Image.file(
                              File(second[index].path),
                              height: 80,
                              width: 80,
                            )),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: GestureDetector(
                      onTap: () {
                        _listFiles(
                            path: items[index].path + "/",
                            image: true);
                      },
                      child: Icon(Icons.file_copy)),
                  title: Text(items[index].path),
                  onTap: () {
                    // Handle the item tap if necessary

                    _listFiles(
                        path: items[index].path + "/",
                        image: false);
                    // Close the bottom sheet
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),);
  }
}
