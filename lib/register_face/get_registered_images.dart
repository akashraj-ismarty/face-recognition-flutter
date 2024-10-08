import 'dart:io';
import 'package:Face_Recognition/loader_ck.dart';
import 'package:Face_Recognition/register_face/register_face_view.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ML/Recognition.dart';
import '../ML/Recognizer.dart';

class RegisteredImages extends StatefulWidget {
  const RegisteredImages({super.key});

  @override
  State<RegisteredImages> createState() => _RegisteredImagesState();
}

class _RegisteredImagesState extends State<RegisteredImages> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addPostFrameCallback((_){
      _imgFromCamera();
      print('Code inside init');

    });
    WidgetsBinding.instance.addObserver(this);
    super.initState();

  }

  @override
  void dispose() {
    faceDetector.close(); // Dispose of the face detector
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _clearCache(); // Clear cache when app is about to exit
    }
  }

  Future<void> _clearCache() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        print("Cache cleared");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  _imgFromCamera() async {
    var  directory;
    if(Platform.isIOS) {
      // directory = await getApplicationDocumentsDirectory();
      await _listFilesForIOS();
    } else if (Platform.isAndroid){
      _listFiles(path: '/storage/emulated/0/', image: false);
    }
  }

  Future<void> _listFilesForIOS({int batchSize = 5}) async {
    List<Album> albums = await PhotoGallery.listAlbums(mediumType: MediumType.image);

    if (albums.isNotEmpty) {
      Album? selectedAlbum = await showDialog<Album>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Select an Album'),
          children: albums.map((album) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, album);
              },
              child: Row(
                children: [
                  Text(album.name ?? 'Unknown Album'),
                ],
              ),
            );
          }).toList(),
        ),
      );

      if (selectedAlbum != null) {
        LoadingDialog.show(context);

        MediaPage mediaPage = await selectedAlbum.listMedia();
        List<FileSystemEntity> data = [];
        List<FileSystemEntity> dataNot = [];

        for (int i = 0; i < mediaPage.items.length; i += batchSize) {
          List<Medium> batch = mediaPage.items.sublist(
            i,
            i + batchSize > mediaPage.items.length ? mediaPage.items.length : i + batchSize,
          );

          for (var medium in batch) {
            File? file = await medium.getFile();
            File downscaledFile = await downscaleImage(file);
            if (await doFaceDetectionFilter(downscaledFile.path)) {
              data.add(downscaledFile);
            } else {
              dataNot.add(downscaledFile);
            }
                    }
          setState(() {
            items = data;
            second = dataNot;
            isImage = true;
          });
        }
        LoadingDialog.hide(context);
      }
    }
  }

  Future<void> _listFiles({required String path, bool image = false, int batchSize = 5}) async {
    LoadingDialog.show(context);
    final directory = Directory(path);

    if (await directory.exists()) {
      var files = directory.listSync();
      if (image) {
        List<FileSystemEntity> imageList = files.where((e) => _isImageFile(e.path) && !(e.path.contains(".trashed"))).toList();
        List<FileSystemEntity> data = [];
        List<FileSystemEntity> dataNot = [];

        for (int i = 0; i < imageList.length; i += batchSize) {
          List<FileSystemEntity> batch = imageList.sublist(
            i,
            i + batchSize > imageList.length ? imageList.length : i + batchSize,
          );

          for (FileSystemEntity entity in batch) {
            File downscaledFile = await downscaleImage(File(entity.path));
            if (await doFaceDetectionFilter(downscaledFile.path)) {
              data.add(downscaledFile);
            } else {
              dataNot.add(downscaledFile);
            }
          }
        }

        setState(() {
          items = data;
          second = dataNot;
          isImage = image;
        });
      } else {
        setState(() {
          items = files;
          second = [];
          isImage = image;
        });
      }
      LoadingDialog.hide(context);
    } else {
      throw Exception("Directory does not exist");
    }
  }

  Future<File> downscaleImage(File imageFile) async {
    ImageProperties properties = await FlutterNativeImage.getImageProperties(imageFile.path);
    int targetWidth = properties.width! ~/ 2; // Example: reduce the width by half
    int targetHeight = (properties.height! * targetWidth / properties.width!).round();

    File compressedFile = await FlutterNativeImage.compressImage(
      imageFile.path,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: 80, // Adjust quality as needed
    );
    return compressedFile;
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

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
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
      print("Recognition Distance  ${recognition.distance}");
      if (recognition.distance > 0.9) {

        recognition.name = "Unknown";
        return false;
      }
      // recognitions.add(recognition);
      return true;
    }
    return false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select an Album',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            items.isEmpty
                ? Text("Browse for a folder or select the entire library")
                : Expanded(
              child: isImage
                  ? SizedBox(
                child: Column(
                  children: [
                    Text('Photos of ${userName}!'),
                    items.isEmpty
                        ? Text("No Item Two")
                        : Expanded(
                      child: GridView.builder(
                          itemCount: items.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4),
                          itemBuilder: (context, index) =>
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (BuildContext context) {
                                      return Dialog(
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              10.0),
                                        ),
                                        child: Container(
                                          padding:
                                          EdgeInsets.all(
                                              20.0),
                                          child: Image.file(
                                            File(items[index]
                                                .path),
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Image.file(
                                  File(items[index].path),
                                  height: 80,
                                  width: 80,
                                ),
                              )),
                    ),
                    Text("Photos of others"),
                    second.isEmpty
                        ? Text("No Item Three")
                        : Expanded(
                      child: GridView.builder(
                          itemCount: second.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4),
                          itemBuilder: (context, index) =>
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (BuildContext context) {
                                      return Dialog(
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              10.0),
                                        ),
                                        child: Container(
                                          padding:
                                          EdgeInsets.all(
                                              20.0),
                                          child: Image.file(
                                            File(second[index]
                                                .path),
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Image.file(
                                  File(second[index].path),
                                  height: 80,
                                  width: 80,
                                ),
                              )),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: ElevatedButton(
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          _listFiles(
                            path: items[index].path + "/",
                            image: true,
                          );
                        } else if (Platform.isIOS) {
                          await _listFilesForIOS();
                        }
                      },
                      child: Text("Select"),
                    ),
                    title: Text(items[index].path),
                    onTap: () async {
                      if (Platform.isAndroid) {
                        _listFiles(
                          path: items[index].path + "/",
                          image: false,
                        );
                      } else if (Platform.isIOS) {
                        await _listFilesForIOS();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}