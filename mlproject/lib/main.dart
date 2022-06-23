import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:requests/requests.dart';
import 'package:excel/excel.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  String _model = yolo;
  File _image;

  Random random = new Random();

  double _imageWidth;
  double _imageHeight;
  bool _busy = false;

  List _recognitions;

  String _nameModel = "Пусто";
  int _priceModel = 0;
  String _linkModel = "Пусто";
  final String file = "/Users/pavel/Desktop/wildberriesshoes.xlsx";

  List data;

  Future<String> loadJsonData() async {
    var jsonText = await rootBundle.loadString('assets/wildBerryParse.json');
    setState(() => data = json.decode(jsonText));
    return 'success';
  }

  _launchURL(url) async {
    if (url == "Пусто")
      return;
    else if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    this.loadJsonData();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
      model: "assets/tflite/yolov2_tiny.tflite",
      labels: "assets/tflite/yolov2_tiny.txt",
    );
  }

  selectFromImagePicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }

  predictImage(File image) async {
    if (image == null) return;

    if (_model == yolo) {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  get_json() async {
    String url =
        "https://www.ozon.ru/search/?from_global=true&text=кеды+lacoste";
    var response = await Requests.get(url);
    var widgets = response.json()["widgetStates"];
    print(widgets);
  }

  yolov2Tiny(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      model: "YOLO",
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1,
    );

    setState(() {
      _recognitions = recognitions;
    });
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  attributes(String namez) {
    for (int i = 0; i < data.length; i++) {
      String name = data[i]["name"];
      if (namez == name.replaceAll('Кроссовки ', '') ||
          namez == name.replaceAll('Кеды ', '')) {
        setState(() {
          _nameModel = data[i]["name"];
          _priceModel = data[i]["price"];
          _linkModel = data[i]["url"];
        });
      }
    }
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageHeight * screen.width;

    return _recognitions.map((re) {
      MaterialColor blue = Colors.blue;
      attributes(re["detectedClass"].toString());

      return Positioned(
          left: 15,
          width: 200,
          height: 20,
          child: Container(
            width: 200,
            height: 20,
            color: Colors.red,
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null
          ? Center(
              child: Container(
                  margin: EdgeInsets.only(top: 120),
                  child: Text("Загрузите изображение")))
          : Image.file(_image),
    ));

    stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Распознаватор обуви"),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          child: Icon(Icons.image),
          tooltip: "Выберите изображение из галереи",
          onPressed: selectFromImagePicker,
        ),
        body: Column(verticalDirection: VerticalDirection.up, children: [
          Flexible(
              child: Stack(
            children: stackChildren,
          )),
          Container(
            height: 120,
            margin: EdgeInsets.all(30),
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      children: [Text("Модель:"), Text(_nameModel)],
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      children: [Text("Цена:"), Text(_priceModel.toString())],
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _launchURL(_linkModel);
                      },
                      child: Text(
                        "Перейти по ссылке",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black)),
                    ))
              ],
            ),
          )
        ]));
  }
}
