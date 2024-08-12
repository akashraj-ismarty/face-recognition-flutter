import 'package:Face_Recognition/RecognitionScreen.dart';
import 'package:Face_Recognition/RegistrationScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ML/Recognition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static Map<String,List<Recognition>> registered = Map();
  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(margin: const EdgeInsets.only(top: 100),child: Image.asset("images/logo.png",width: screenWidth-40,height: screenWidth-40,)),
         const Column(children: [
           Text("Welcome To" , style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
           Text("The Last Three" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
         ],),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            /*child: Column(
              children: [
                ElevatedButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const RegistrationScreen()));
                },
                  style: ElevatedButton.styleFrom(minimumSize: Size(screenWidth-30, 50)), child: const Text("Register"),),
                Container(height: 20,),
                ElevatedButton(onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>const RecognitionScreen()));
                },
                  style: ElevatedButton.styleFrom(minimumSize: Size(screenWidth-30, 50)), child: const Text("Recognize"),),
              ],
            ),*/

             child:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(200))),
                    child: InkWell(
                      onTap: () {

                      },
                      child: SizedBox(
                        width: screenWidth / 2 - 70,
                        height: screenWidth / 2 - 70,
                        child: Icon(Icons.image,
                            color: Colors.blue, size: screenWidth / 7),
                      ),
                    ),
                  ),
                  Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(200))),
                    child: InkWell(
                      onTap: () {

                      },
                      child: SizedBox(
                        width: screenWidth / 2 - 70,
                        height: screenWidth / 2 - 70,
                        child: Icon(Icons.camera,
                            color: Colors.blue, size: screenWidth / 7),
                      ),
                    ),
                  )
                ],
              )
          ),

        ],
      ),
    );
  }
}
