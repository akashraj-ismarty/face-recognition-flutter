import 'dart:io';

import 'package:Face_Recognition/RegistrationScreen.dart';
import 'package:Face_Recognition/register_face/faces_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../ML/Recognition.dart';
import '../ML/Recognizer.dart';
import 'get_registered_images.dart';

class RegisterFaceView extends StatefulWidget {
  const RegisterFaceView({super.key});

  @override
  State<RegisterFaceView> createState() => _RegisterFaceViewState();
}

class _RegisterFaceViewState extends State<RegisterFaceView> {
  List<File> _images = [];
  List<FaceImages> faceImages = [];
  dynamic faceDetector;

  //TODO declare face recognizer
  TextEditingController controller = TextEditingController();
  final Recognizer _recognizer = Recognizer();

  @override
  void initState() {
    //TODO initialize detector
    final options = FaceDetectorOptions(
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false);

    //TODO initialize face detector
    faceDetector = FaceDetector(options: options);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            TextFormField(
              controller: controller,
            ),
            Flexible(
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) => Image.file(_images[index]),
                itemCount: _images.length,
              ),
            ),
            Flexible(
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) => FittedBox(
                  child: SizedBox(
                    height: faceImages[index].image.height.toDouble(),
                    width: faceImages[index].image.width.toDouble(),
                    child: CustomPaint(
                      painter: FacePainter(
                          facesList: faceImages[index].faces,
                          imageFile: faceImages[index].image),
                    ),
                  ),
                ),
                itemCount: faceImages.length,
              ),
            ),
            GestureDetector(
                onTap: () {
                  _imgFromGallery();
                },
                child: Container(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("Pick 3 Images")),
                )),
            ElevatedButton(
                onPressed: () {
                  continueSaving();
                },
                child: Text("Continue"))
          ],
        ),
      ),
    );
  }

  //TODO capture image using camera
  _imgFromGallery() async {
    List<XFile>? pickedFile = await ImagePicker().pickMultiImage();
    if (pickedFile != null) {
      pickedFile.forEach((e) => _images.add(File(e.path)));

      setState(() {});
    }
  }

  continueSaving() async {
    List<Recognition> data;
    data =
        await Future.wait<Recognition>(_images.map((e) => doFaceDetection(e)));

    averageEmbedding(data);

  }

  Future<Recognition> doFaceDetection(File file) async {
    //TODO remove rotation of camera images
    File image = await removeRotation(file);

    //TODO passing input to face detector and getting detected faces
    final inputImage = InputImage.fromFile(image);
    List<Face> faces = await faceDetector.processImage(inputImage);
    return performFaceRecognition(file, faces);
  }

  removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage!.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(inputImage.path)
        .writeAsBytes(img.encodeJpg(orientedImage));
  }

  Future<Recognition> performFaceRecognition(
      File imgFile, List<Face> faces) async {
    var dataimage = await imgFile?.readAsBytes();
    var image = await decodeImageFromList(dataimage!);

    print("${image.width}   ${image.height}");

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      num left = faceRect.left < 0 ? 0 : faceRect.left;
      num top = faceRect.top < 0 ? 0 : faceRect.top;
      num right =
          faceRect.right > image.width ? image.width - 1 : faceRect.right;
      num bottom =
          faceRect.bottom > image.height ? image.height - 1 : faceRect.bottom;
      num width = right - left;
      num height = bottom - top;

      //TODO crop face
      File cropedFace = await FlutterNativeImage.cropImage(imgFile!.path,
          left.toInt(), top.toInt(), width.toInt(), height.toInt());
      final bytes = await File(cropedFace!.path).readAsBytes();
      final img.Image? faceImg = img.decodeImage(bytes);
      setState(() {
        print("Face Image ${faceImg.runtimeType}");
      });
      if (face.boundingBox.width > 0) {
        Recognition recognition =
            _recognizer.recognize(faceImg!, face.boundingBox);
        faceImages.add(FaceImages(image, faces));
        return recognition;
        // recognizedFaces.add(recognition);

        //TODO show face registration dialogue
        // showFaceRegistrationDialogue(cropedFace, recognition);
      }
      // drawRectangleAroundFaces();
    }
    throw ("Not able to recognize");
  }

  // drawRectangleAroundFaces(File image) async {
  //   image = await _image?.readAsBytes();
  //   image = await decodeImageFromList(image);
  //   print("${image.width}   ${image.height}");
  //   setState(() {
  //     image;
  //     faces;
  //   });
  // }
  averageEmbedding(List<Recognition> data) {
    // List<double> average =
    //     List.generate(data[0].embeddings[0].length, (e) => 0);
    //
    // data.forEach((e) {
    //   for (int i = 0; i < e.embeddings[0].length; i++) {
    //     average[i] = average[i] + e.embeddings[0][i];
    //   }
    // });
    // average = average.map((e) => e / 3).toList();
    //
    // Recognition averageReco = data[0];
    // averageReco.embeddings = [average];
    DataModel.registered['${controller.text}'] = [data[0]];
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RegisteredImages()));
  }
}

class FaceImages {
  var image;
  List<Face> faces;

  FaceImages(this.image, this.faces);
}
