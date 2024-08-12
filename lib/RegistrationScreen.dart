import 'dart:developer';
import 'dart:io';
import 'package:Face_Recognition/HomeScreen.dart';
import 'package:Face_Recognition/ML/Recognition.dart';
import 'package:Face_Recognition/loading_animation.dart';
import 'package:Face_Recognition/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'ML/Recognizer.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _HomePageState();
}

class _HomePageState extends State<RegistrationScreen> {

  bool isLoader = false;
  bool showRegistrationDialog = false; // Flag to control dialog display

  //TODO declare variables
  late ImagePicker imagePicker;
  File? _image;
  List<File> _imagesthree = [];
  List<Recognition> recognizedFaces = [];

  var image;
  List<Face> faces = [];
  //TODO declare detector
  dynamic faceDetector;

  List<double>? averageEmbeddings;
  //TODO declare face recognizer
  final Recognizer _recognizer = Recognizer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imagePicker = ImagePicker();

    //TODO initialize detector
    final options = FaceDetectorOptions(
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false);

    //TODO initialize face detector
    faceDetector = FaceDetector(options: options);

    //TODO initialize face recognizer
    // _recognizer = ;
  }

  //TODO capture image using camera
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doFaceDetection();
    }
  }

  //TODO choose image using gallery
  // _imgFromGallery() async {
  //   List<XFile>? pickedFiles = await imagePicker.pickMultiImage();
  //   if (pickedFiles != null) {
  //     for (var pickedFile in pickedFiles) {
  //       _image = File(pickedFile.path);
  //       setState(() {
  //         isLoader = true;
  //       });
  //       doFaceDetection();
  //     }
  //   }
  // }

  _imgFromGallery() async {
    final pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        isLoader = true;
        _imagesthree.clear(); // Clear previous selections
      });
      for (var pickedFile in pickedFiles) {
        _imagesthree.add(File(pickedFile.path));
      }
      await processAllImages(); // Call a new method to handle all images
    }
  }

  Future<void> processAllImages() async {
    List<Recognition> allRecognitions = []; // Store recognitions for averaging
    for (var imageFile in _imagesthree) {
      _image = imageFile; // Update _image for each iteration
      await doFaceDetection(); // Perform detection and recognition for each image
      allRecognitions.addAll(recognizedFaces); // Add recognized faces to list
    }

    // Calculate average embeddings (assuming recognizedFaces contains Recognition objects)
    if (allRecognitions.isNotEmpty) {
      List<double> averageEmbeddings = List.generate(allRecognitions[0].embeddings[0].length, (i) => 0.0);
      for (var recognition in allRecognitions) {
        for (int j = 0; j < recognition.embeddings.length; j++) {
          averageEmbeddings[j] += recognition.embeddings[j][0]; // Assuming single embedding per face
        }
      }
      for (int i = 0; i < averageEmbeddings.length; i++) {
        averageEmbeddings[i] /= allRecognitions.length;
      }
      this.averageEmbeddings = averageEmbeddings;
      showRegistrationDialog = true;
    }

    setState(() {
      isLoader = false;
    });
  }





  //TODO face detection code here
  TextEditingController textEditingController = TextEditingController();
  doFaceDetection() async {
    faces.clear();

    //TODO remove rotation of camera images
    _image = await removeRotation(_image!);

    //TODO passing input to face detector and getting detected faces
    final inputImage = InputImage.fromFile(_image!);
    faces = await faceDetector.processImage(inputImage);
    faces.forEach((e)=>print("face;-data " +e.boundingBox.bottom.toString()));

    //TODO call the method to perform face recognition on detected faces
    try {
      performFaceRecognition();
    }catch(e,st){
      log("performFaceRecognition",stackTrace: st,error: e,name: "performFaceRecognition");
    }
  }

  //TODO remove rotation of camera images
  removeRotation(File inputImage) async {
    final img.Image? capturedImage = img.decodeImage(await File(inputImage!.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  //TODO perform Face Recognition
  performFaceRecognition() async {
   var dataimage = await _image?.readAsBytes();
    image = await decodeImageFromList(dataimage!);

    print("${image.width}   ${image.height}");

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      num left = faceRect.left<0?0:faceRect.left;
      num top = faceRect.top<0?0:faceRect.top;
      num right = faceRect.right>image.width?image.width-1:faceRect.right;
      num bottom = faceRect.bottom>image.height?image.height-1:faceRect.bottom;
      num width = right - left;
      num height = bottom - top;

      //TODO crop face
      File cropedFace = await FlutterNativeImage.cropImage(
          _image!.path,
          left.toInt(),top.toInt(),width.toInt(),height.toInt());
      final bytes = await File(cropedFace!.path).readAsBytes();
      final img.Image? faceImg = img.decodeImage(bytes);
      setState(() {
      print("Face Image ${faceImg.runtimeType}");
      });
      if(face.boundingBox.width>0){
      Recognition recognition = _recognizer.recognize(faceImg!, face.boundingBox);
      recognizedFaces.add(recognition);

      //TODO show face registration dialogue
      print("Show Dialog");
      showFaceRegistrationDialogue(cropedFace, recognition, averageEmbeddings);
      }
    }
    drawRectangleAroundFaces();
  }

  //TODO Face Registration Dialogue
  showFaceRegistrationDialogue(File cropedFace, Recognition recognition, List<double> averageEmbeddings){
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration",textAlign: TextAlign.center),alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20,),
              Image.file(
                cropedFace,
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: textEditingController,
                    decoration: const InputDecoration( fillColor: Colors.white, filled: true,hintText: "Enter Name")
                ),
              ),
              const SizedBox(height: 10,),
              ElevatedButton(
                  onPressed: () {
                    HomeScreen.registered[textEditingController.text] = [Recognition(textEditingController.text, Rect.zero, [averageEmbeddings], 0.0)];
                    // HomeScreen.registered[ textEditingController.text] = [...(HomeScreen.registered[ textEditingController.text]??[]),recognition];
                    // HomeScreen.registered.putIfAbsent(
                    //     textEditingController.text, () => recognition);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    setState(() {
                      isLoader = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },style: ElevatedButton.styleFrom(backgroundColor:Colors.blue,minimumSize: const Size(200,40)),
                  child: const Text("Register"))
            ],
             
          ),
        ),contentPadding: EdgeInsets.zero,
      ),
    );
  }
  //TODO draw rectangles
  drawRectangleAroundFaces() async {
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    print("${image.width}   ${image.height}");
    setState(() {
      image;
      faces;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    print("Type of image = ${image.runtimeType}");
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              image != null
                  ? Container(
                margin: const EdgeInsets.only(
                    top: 60, left: 30, right: 30, bottom: 0),
                child: FittedBox(
                  child: SizedBox(
                    width: image.width.toDouble(),
                    height: image.width.toDouble(),
                    child: CustomPaint(
                      painter: FacePainter(
                          facesList: faces, imageFile: image),
                    ),
                  ),
                ),
              )
                  : Container(
                margin: const EdgeInsets.only(top: 100),
                child: Image.asset(
                  "images/logo.png",
                  width: screenWidth - 100,
                  height: screenWidth - 100,
                ),
              ),

              Container(
                height: 50,
              ),

              //section which displays buttons for choosing and capturing images
              Container(
                margin: const EdgeInsets.only(bottom: 50),
                child: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(200))),
                  child: InkWell(
                    onTap: () {
                      _imgFromGallery();
                    },
                    child: SizedBox(
                      width: screenWidth / 2 - 70,
                      height: screenWidth / 2 - 70,
                      child: Icon(Icons.image,
                          color: Colors.blue, size: screenWidth / 7),
                    ),
                  ),
                ),
              )
            ],
          ),
          if(isLoader) const LoadingAnimation()
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> facesList;
  dynamic imageFile;
  FacePainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;

    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, p);
    }

    Paint p2 = Paint();
    p2.color = Colors.green;
    p2.style = PaintingStyle.stroke;
    p2.strokeWidth = 3;

    Paint p3 = Paint();
    p3.color = Colors.yellow;
    p3.style = PaintingStyle.stroke;
    p3.strokeWidth = 1;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
