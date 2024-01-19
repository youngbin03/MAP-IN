import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:image/image.dart' as img;

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mao/model/map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'contacts_info.dart';

class FindFriends extends StatefulWidget {
  final File? profileImage;

  const FindFriends({Key? key, this.profileImage}) : super(key: key);

  @override
  _FindFriendsState createState() => _FindFriendsState();
}

late GoogleMapController _controller;
double ScreenMaxHeight = 500;

class _FindFriendsState extends State<FindFriends> {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.557175077529935, 127.03809359848501),
    zoom: 14.4746,
  );

  Set<Marker> _markers = {};
  Map<String, Marker> _info_markers = {};
  //late GoogleMapController _controller;
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  late Uint8List markerIcon;
  //late XFile _userImage;
  LocationData? _userLocation;
  List _contacts = contacts;
  String _currentAddress = 'My Location..';

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
    _getUserLocation();
    _updateCurrentAddress();
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  // void setCustomMapPin() async {
  //   markerIcon = await getBytesFromAsset('assets/images/check.png', 130);
  // }
  Future<Uint8List> resizeAndClipImage(File image, int targetSize) async {
    try {
      final imageBytes = await image.readAsBytes();
      final resizedBytes = await resizeImage(imageBytes, targetSize);
      final circularImage = await getCircularImage(resizedBytes);
      final outlinedImage = await addRainbowOutline(circularImage, targetSize);
      final outlinedBytes =
          await outlinedImage.toByteData(format: ui.ImageByteFormat.png);
      return outlinedBytes!.buffer.asUint8List();
    } catch (e) {
      // 오류가 발생한 경우 처리
      print("Error resizing and clipping image: $e");
      return Uint8List(0); // 빈 리스트나 기본값으로 대체할 수 있음
    }
  }

  Future<Uint8List> resizeImage(Uint8List imageData, int targetSize) async {
    final originalImage = img.decodeImage(imageData)!;
    final resizedImage =
        img.copyResize(originalImage, width: targetSize, height: targetSize);
    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  Future<ui.Image> getCircularImage(Uint8List inputImage) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();

    ui.decodeImageFromList(Uint8List.fromList(inputImage),
        (ui.Image img) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final Paint paint = Paint()
        ..color = Colors.white // Background color (you can set it to any color)
        ..style = PaintingStyle.fill;

      // Draw a white circular background
      canvas.drawCircle(
          Offset(img.width / 2, img.height / 2), img.width / 2, paint);

      // Draw the circular image on top of the white background
      paint.blendMode = BlendMode.srcIn;
      canvas.drawImage(img, Offset.zero, paint);

      // Create a picture and finalize the recorder
      final picture = recorder.endRecording();
      final circularImage = await picture.toImage(img.width, img.height);

      completer.complete(circularImage);
    });

    return completer.future;
  }

  Future<ui.Image> addRainbowOutline(ui.Image inputImage, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Define a rainbow gradient
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: [
        ui.Color.fromARGB(255, 39, 123, 176),
        Colors.yellow,
        Colors.orange,
        const ui.Color.fromARGB(255, 244, 54, 54),
        const ui.Color.fromARGB(255, 191, 33, 243),
        const ui.Color.fromARGB(255, 120, 63, 181),
        ui.Color.fromARGB(255, 39, 53, 176),
      ],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(
          center: Offset(size / 2, size / 2), radius: size / 2 - 3))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round // Rounded corners
      ..strokeWidth =
          5.0; // You can adjust this value for the desired thickness

    // Draw a circular background with a stroke using the rainbow gradient
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, paint);

    // Draw the circular image on top of the rainbow background
    paint.blendMode = BlendMode.dstOver;
    canvas.drawImage(inputImage, Offset.zero, paint);

    // Create a picture and finalize the recorder
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    return img;
  }

  void setCustomMapPin() async {
    if (widget.profileImage != null) {
      final resizedBytes = await resizeAndClipImage(widget.profileImage!, 130);
      setState(() {
        markerIcon = resizedBytes;
      });
    } else {
      // forileImage가 null일 때의 기본 이미지 설정 (예: 'assets/images/default_marker.png')
      markerIcon = await getBytesFromAsset('assets/images/avatar-8.png', 130);
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _updateCurrentAddress() async {
    await _getUserLocation();
    try {
      if (_userLocation != null) {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          _userLocation!.latitude!,
          _userLocation!.longitude!,
          localeIdentifier: "en",
        );

        if (placemarks.isNotEmpty) {
          geo.Placemark placemark = placemarks[0];
          String address = '${placemark.thoroughfare}-'
              '${placemark.subLocality}-${placemark.locality}${placemark.administrativeArea}';

          setState(() {
            _currentAddress = address;
          });
        }
      }
    } catch (e) {
      print('주소를 가져오는 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    //createMarkers(context);
    ScreenMaxHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _kGooglePlex,
          markers: {..._markers, ..._info_markers.values.toSet()},
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
            controller.setMapStyle(MapStyle().aubergine);
            _customInfoWindowController.googleMapController = controller;
            _updateCurrentAddress();
            //createMarkers(context);
          },
          // onTap: (LatLng latLng) {
          //   _customInfoWindowController.hideInfoWindow!();
          //   Marker marker = Marker(
          //     icon: BitmapDescriptor.fromBytes(markerIcon),
          //     draggable: true,
          //     markerId: MarkerId(latLng.toString()),
          //     position: latLng,
          //     // onTap: () {
          //     //   _customInfoWindowController.addInfoWindow!(
          //     //     Stack(
          //     //       children: [
          //     //         Container(
          //     //           padding: EdgeInsets.all(15.0),
          //     //           decoration: BoxDecoration(
          //     //             borderRadius: BorderRadius.circular(15.0),
          //     //             color: Colors.white,
          //     //           ),
          //     //           child: SingleChildScrollView(
          //     //             child: Column(
          //     //               crossAxisAlignment: CrossAxisAlignment.start,
          //     //               children: [
          //     //                 Container(
          //     //                   width: double.infinity,
          //     //                   height: 130,
          //     //                   child: ClipRRect(
          //     //                     borderRadius: BorderRadius.circular(10.0),
          //     //                     child: Image.network(
          //     //                       'https://private-user-images.githubusercontent.com/87307678/284766602-3f991bf8-b284-4841-bef9-8933298df6d5.JPG?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTEiLCJleHAiOjE3MDA2MTk1NjksIm5iZiI6MTcwMDYxOTI2OSwicGF0aCI6Ii84NzMwNzY3OC8yODQ3NjY2MDItM2Y5OTFiZjgtYjI4NC00ODQxLWJlZjktODkzMzI5OGRmNmQ1LkpQRz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFJV05KWUFYNENTVkVINTNBJTJGMjAyMzExMjIlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjMxMTIyVDAyMTQyOVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWYxMDQ1NmEwN2RmYjAwYWYxODhkZWY2NGE5ODRkMzIxNmNmZGUxNGFkMDBkMjhmYjI3ZTU1M2M3YjFiMTYxMzcmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.MbVzjbd-SOiiYewZMg8PGPBzHOR1rKivjc8K23MFBlo',
          //     //                       fit: BoxFit.cover,
          //     //                     ),
          //     //                   ),
          //     //                 ),
          //     //                 SizedBox(
          //     //                   height: 15,
          //     //                 ),
          //     //                 Text(
          //     //                   "Hanyang University Station Aejumun",
          //     //                   style: TextStyle(
          //     //                       color: Colors.black,
          //     //                       fontWeight: FontWeight.bold,
          //     //                       fontSize: 14),
          //     //                 ),
          //     //                 SizedBox(
          //     //                   height: 5,
          //     //                 ),
          //     //                 Text(
          //     //                   "실시간 한양대학교 전과자 촬영중!",
          //     //                   style: TextStyle(
          //     //                       color: Colors.grey.shade600, fontSize: 12),
          //     //                 ),
          //     //                 SizedBox(
          //     //                   height: 8,
          //     //                 ),
          //     //                 MaterialButton(
          //     //                   onPressed: () {},
          //     //                   elevation: 0,
          //     //                   height: 40,
          //     //                   minWidth: double.infinity,
          //     //                   color: Colors.grey.shade200,
          //     //                   shape: RoundedRectangleBorder(
          //     //                     borderRadius: BorderRadius.circular(10.0),
          //     //                   ),
          //     //                   child: Text(
          //     //                     "See details",
          //     //                     style: TextStyle(color: Colors.black),
          //     //                   ),
          //     //                 )
          //     //               ],
          //     //             ),
          //     //           ),
          //     //         ),
          //     //         Positioned(
          //     //           top: 5.0,
          //     //           left: 5.0,
          //     //           child: IconButton(
          //     //             icon: Icon(
          //     //               Icons.close,
          //     //               color: Colors.white,
          //     //             ),
          //     //             onPressed: () {
          //     //               _customInfoWindowController.hideInfoWindow!();
          //     //             },
          //     //           ),
          //     //         ),
          //     //       ],
          //     //     ),
          //     //     latLng,
          //     //   );
          //     // },
          //   );

          //   setState(() {
          //     _info_markers[latLng.toString()] = marker;
          //   });
          // },
          onCameraMove: (position) {
            _customInfoWindowController.onCameraMove!();
          },
        ),
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: MediaQuery.of(context).size.height * 0.35,
          width: MediaQuery.of(context).size.width * 0.5,
          offset: 60.0,
        ),
        Positioned(
          bottom: 50,
          left: MediaQuery.of(context).size.width / 2 - 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkResponse(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 5, 40, 0.922).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.0), // 버튼 모양 조절
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0), // 내부 여백
                    child: Image.asset(
                      'assets/icons/icons8-chat-90.png',
                      color: Colors.white,
                      width: 24.0, // 원하는 폭으로 조정
                      height: 24.0, // 원하는 높이로 조정
                    ),
                  ),
                ),
              ),
              SizedBox(width: 18.0), // 간격 조절
              SizedBox(
                width: 60,
                height: 60,
                child: FittedBox(
                  child: FloatingActionButton(
                    onPressed: () async {
                      await _getUserImage();
                      await _getUserLocation();
                    },
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: Icon(Icons.camera_alt),
                  ),
                ),
              ),
              SizedBox(width: 18.0), // 간격 조절
              InkResponse(
                onTap: () {
                  _showBottomSheet(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 5, 40, 0.922).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.0), // 버튼 모양 조절
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0), // 내부 여백
                    child: Icon(
                      Icons.person_search,
                      color: Colors.white, // 아이콘 색상
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        Positioned(
          top: 100,
          right: 20,
          child: GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: 20,
          child: GestureDetector(
            onTap: () {
              if (_userLocation != null) {
                setState(() {
                  _getUserLocation();
                  _updateCurrentAddress();
                  CameraPosition targetPosition = CameraPosition(
                    target: LatLng(
                      _userLocation!.latitude!,
                      _userLocation!.longitude!,
                    ),
                    zoom: 14.0, // 원하는 줌 레벨
                  );

                  CameraUpdate cameraUpdate =
                      CameraUpdate.newCameraPosition(targetPosition);

                  _controller.animateCamera(cameraUpdate);
                });
              }
            },
            child: Icon(
              Icons.my_location,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        Positioned(
          top: 50.0,
          left: 20.0,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 260.0, // 텍스트의 최대 가로 크기 설정
            ),
            child: Text(
              '$_currentAddress',
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
                decorationThickness: 1.0,
              ),
              maxLines: 2, // 허용할 최대 줄 수
              overflow: TextOverflow.clip, // 생략 부호 대신 텍스트를 자르도록 설정
              softWrap: true, // 줄 바꿈 허용
            ),
          ),
        ),
        // Positioned(
        //   top: 24.0,
        //   right: 24.0,
        //   child: ElevatedButton(
        //     onPressed: () {},
        //     style: ElevatedButton.styleFrom(
        //       primary: Colors.white.withOpacity(0.8),
        //     ),
        //     child: Icon(
        //         Icons.person), //child: Image.file(image!, fit: BoxFit.cover),
        //   ),
        // ), 23.11.25
        // Positioned(
        //   top: 50,
        //   left: 20,
        //   right: 20,
        //   child: Container(
        //       width: MediaQuery.of(context).size.width,
        //       height: 120,
        //       decoration: BoxDecoration(
        //           color: Colors.white.withOpacity(0.8),
        //           borderRadius: BorderRadius.circular(20)),
        //       child: ListView.builder(
        //         scrollDirection: Axis.horizontal,
        //         itemCount: _contacts.length,
        //         itemBuilder: (context, index) {
        //           return GestureDetector(
        //             onTap: () {
        //               _controller.moveCamera(
        //                   CameraUpdate.newLatLng(_contacts[index]["position"]));
        //             },
        //             child: Container(
        //               width: 100,
        //               height: 100,
        //               margin: EdgeInsets.only(right: 10),
        //               child: Column(
        //                 mainAxisAlignment: MainAxisAlignment.center,
        //                 children: [
        //                   Image.asset(
        //                     _contacts[index]['image'],
        //                     width: 60,
        //                   ),
        //                   SizedBox(
        //                     height: 10,
        //                   ),
        //                   Text(
        //                     _contacts[index]["name"],
        //                     style: TextStyle(
        //                         color: Colors.black,
        //                         fontWeight: FontWeight.w600),
        //                   )
        //                 ],
        //               ),
        //             ),
        //           );
        //         },
        //       )),
        // )
      ],
    ));
  }

  createMarkers(BuildContext context) {
    Marker marker;

    _contacts.forEach((contact) async {
      marker = Marker(
        markerId: MarkerId(contact['name']),
        position: contact['position'],
        icon: await _getAssetIcon(context, contact['marker'])
            .then((value) => value),
        infoWindow: InfoWindow(
          title: contact['name'],
          snippet: 'Street 6 . 2min ago',
        ),
      );

      setState(() {
        _markers.add(marker);
      });
    });
  }

  void removeMarkers(int n) {
    if (n == 0) {
      _info_markers.forEach((key, marker) {
        _controller.hideMarkerInfoWindow(MarkerId(key));
      });
      _info_markers.clear();
    } else {
      // _marker를 지도에서 제거하는 부분 추가
      _markers.forEach((marker) {
        _controller.hideMarkerInfoWindow(marker.markerId);
      });
      _markers.clear();
    }
  }
  // Future<void> _getUserImage(BuildContext context) async {
  //   final ImagePicker _picker = ImagePicker();
  //   XFile? image = await _picker.pickImage(source: ImageSource.camera);

  //   if (image != null) {
  //     setState(() {
  //       _userImage = image!;
  //     });
  //   }
  // }
  void _showBottomSheet(BuildContext context) {
    //removeMarkers(0); // 기존 info_marker 제거
    createMarkers(context); // _marker 추가
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 1000,
      builder: (BuildContext context) {
        return AnimatedBottomSheet();
      },
    ).whenComplete(() {
      setState(() {
        _getUserLocation();
        CameraPosition targetPosition = CameraPosition(
          target: LatLng(
            _userLocation!.latitude!,
            _userLocation!.longitude!,
          ),
          zoom: 14.0, // 원하는 줌 레벨
        );

        CameraUpdate cameraUpdate =
            CameraUpdate.newCameraPosition(targetPosition);

        _controller.animateCamera(cameraUpdate);
      });
      // bottom sheet가 닫힐 때의 콜백
      removeMarkers(1); // _marker 제거
      //createMarkers(context); // info_marker 추가
    });
  }

  File? image;
  Future _getUserImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;

      final imageTemporary = File(image.path);
      this.image = imageTemporary;
      setState(() => this.image = imageTemporary);

      // 사용자로부터 텍스트 입력 받기
      _getUserLocation();
      _showTextInputDialog();
      if (_userLocation != null) {
        CameraPosition targetPosition = CameraPosition(
          target: LatLng(
            _userLocation!.latitude!,
            _userLocation!.longitude!,
          ),
          zoom: 14.0, // 원하는 줌 레벨
        );

        CameraUpdate cameraUpdate =
            CameraUpdate.newCameraPosition(targetPosition);

        _controller.animateCamera(cameraUpdate);
      }
    } on PlatformException catch (e) {
      print('Failed to upload image: $e');
    }
  }

  Future<BitmapDescriptor> _getAssetIcon(
      BuildContext context, String icon) async {
    final Completer<BitmapDescriptor> bitmapIcon =
        Completer<BitmapDescriptor>();
    final ImageConfiguration config =
        createLocalImageConfiguration(context, size: Size(5, 5));

    AssetImage(icon)
        .resolve(config)
        .addListener(ImageStreamListener((ImageInfo image, bool sync) async {
      final ByteData? bytes =
          await image.image.toByteData(format: ui.ImageByteFormat.png);
      final BitmapDescriptor bitmap =
          BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
      bitmapIcon.complete(bitmap);
    }));

    return await bitmapIcon.future;
  }

  Future<void> _getUserLocation() async {
    LocationData? locationData = await Location().getLocation();
    if (locationData != null) {
      setState(() {
        _userLocation = locationData;
      });
    }
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController descriptionController = TextEditingController();
        TextEditingController titleController = TextEditingController();
        double screenHeight = MediaQuery.of(context).size.height;
        double screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.8),
          content: SingleChildScrollView(
            child: Container(
              width: screenWidth * 0.7, // 원하는 너비로 설정합니다.
              height: screenHeight * 0.45,
              child: Column(
                children: [
                  // 이미지 추가 부분
                  Container(
                    width: double.infinity,
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(image!, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: "Enter title"),
                  ),
                  SizedBox(height: 15),
                  // 설명 입력 텍스트 필드 (다중 라인)
                  Expanded(
                    child: TextField(
                      expands: true,
                      controller: descriptionController,
                      maxLines: null, // 다중 라인을 지원하도록 null로 설정
                      decoration: InputDecoration(
                        hintText: "Enter description",
                        border: OutlineInputBorder(), // 텍스트 필드에 외곽선 추가
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                String markerTitle = titleController.text;
                String markerDescription = descriptionController.text;
                Navigator.pop(context);

                if (markerTitle.isNotEmpty && _userLocation != null) {
                  // 사용자가 입력한 텍스트를 기반으로 마커 생성
                  _addMarkerWithImageAndText(
                    image!,
                    LatLng(
                      _userLocation!.latitude!,
                      _userLocation!.longitude!,
                    ),
                    markerTitle,
                    markerDescription,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Text cannot be empty'),
                    ),
                  );
                }
              },
              child: Text(
                "OK",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addMarkerWithImageAndText(
      File image, LatLng latLng, String titleText, String descriptionText) {
    double ScreenMaxHeight = MediaQuery.of(context).size.height;
    Marker marker = Marker(
      icon: BitmapDescriptor.fromBytes(markerIcon),
      draggable: true,
      markerId: MarkerId(latLng.toString()),
      position: latLng,
      onTap: () {
        _customInfoWindowController.addInfoWindow!(
          Stack(
            children: [
              CustomPaint(
                painter: CustomInfoWindowPainter(),
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지 추가 부분
                        Container(
                          width: double.infinity,
                          height: 130,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.file(image, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          titleText,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          descriptionText,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        MaterialButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              barrierColor: Colors.transparent,
                              isScrollControlled: true,
                              scrollControlDisabledMaxHeightRatio:
                                  ScreenMaxHeight - 50,
                              builder: (BuildContext context) {
                                return AnimatedDetailSheet(
                                  profile: widget.profileImage,
                                  image: image,
                                  latLng: latLng,
                                  titleText: titleText,
                                  descriptionText: descriptionText,
                                );
                              },
                            );
                          },
                          elevation: 0,
                          height: 40,
                          minWidth: double.infinity,
                          color: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            "See details",
                            style: TextStyle(color: Colors.black),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5.0,
                left: 5.0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _customInfoWindowController.hideInfoWindow!();
                  },
                ),
              ),
            ],
          ),
          latLng,
        );
      },
    );
    setState(() {
      _info_markers[latLng.toString()] = marker;
    });
  }
}

class AnimatedDetailSheet extends StatefulWidget {
  final File? profile;
  final File? image;
  final LatLng latLng;
  final String titleText;
  final String descriptionText;

  const AnimatedDetailSheet({
    Key? key,
    this.profile,
    this.image,
    required this.latLng,
    required this.titleText,
    required this.descriptionText,
  }) : super(key: key);

  @override
  State<AnimatedDetailSheet> createState() => _AnimatedDetailSheetState();
}

class _AnimatedDetailSheetState extends State<AnimatedDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: ScreenMaxHeight = MediaQuery.of(context).size.height - 50,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0), // 왼쪽 위 둥글게
            topRight: Radius.circular(20.0), // 오른쪽 위 둥글게
          ),
          boxShadow: [
            BoxShadow(
              color: ui.Color.fromARGB(255, 0, 0, 50), // 그림자 색상
              spreadRadius: 2, // 그림자 확산 정도
              blurRadius: 5, // 그림자 흐림 정도
              offset: Offset(0, 2), // 그림자 위치 (x, y)
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[500],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // 모서리를 둥글게 설정
                      child: widget.profile != null
                          ? Container(
                              width: 60,
                              height: 60,
                              child: Image.file(widget.profile!,
                                  width: 60, height: 60, fit: BoxFit.cover),
                            )
                          : Image.asset(
                              'assets/images/avatar-8.png', // 변경하려는 이미지의 경로
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(width: 16.0), // 이미지와 이름 간격 조절
                  // 이름을 담은 Container
                  Container(
                    child: Text(
                      'SINBOIN', // 사용자의 이름 또는 텍스트로 변경
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(), // 메뉴 아이콘을 오른쪽 끝에 정렬하기 위한 Spacer
                  IconButton(
                    icon: Icon(Icons.more_horiz,
                        size: 40,
                        color: Colors.white.withOpacity(0.5)), // 메뉴 아이콘으로 변경 가능
                    onPressed: () {
                      // 메뉴 아이콘 클릭 시 수행할 동작
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.8), // 원하는 배경색으로 설정
                  borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지 추가 부분
                      Container(
                        width: double.infinity,
                        height: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(widget.image!, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        widget.titleText,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 34),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        widget.descriptionText,
                        style: TextStyle(color: Colors.grey[500], fontSize: 18),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      Divider(
                        color: Colors.grey[600],
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.forum, // 사용할 아이콘 지정
                            color: Colors.white,
                            size: 24.0,
                          ),
                          SizedBox(width: 8.0), // 아이콘과 텍스트 사이의 간격 조절
                          Text(
                            'Comments', // 댓글 섹션 제목
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      // 댓글을 입력할 수 있는 TextField
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class AnimatedBottomSheet extends StatefulWidget {
  const AnimatedBottomSheet({Key? key}) : super(key: key);
  @override
  State<AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet> {
  List _contacts = contacts;
  FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // 다음 프레임에서 포커스를 설정합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
    // TextEditingController에 리스너 추가
    _focusNode.addListener(() {
      setState(() {
        // 텍스트 입력 중인지 여부를 감지
        _isTyping = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // 반드시 dispose 메서드에서 FocusNode를 dispose 해야 합니다.
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenMaxHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: ui.Color.fromARGB(255, 0, 0, 50), // 배경색 설정
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0), // 왼쪽 위 둥글게
          topRight: Radius.circular(20.0), // 오른쪽 위 둥글게
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // 그림자 색상
            spreadRadius: 2, // 그림자 확산 정도
            blurRadius: 5, // 그림자 흐림 정도
            offset: Offset(0, 2), // 그림자 위치 (x, y)
          ),
        ],
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1), // 시작 위치 (하단에서 시작)
          end: Offset.zero, // 종료 위치 (화면 상단으로 슬라이드)
        ).animate(
          CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeInOut,
          ),
        ),
        child: AnimatedSize(
          duration: Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          // 이 코드를 추가하여 상태를 동기화합니다.
          child: Container(
            height: _isTyping ? ScreenMaxHeight * 0.75 : 300,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Set to start
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬로 변경
              children: [
                SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 80,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[500],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.only(left: 20), // 여기에 margin을 설정
                  child: Text(
                    "Friends",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                    margin: EdgeInsets.only(right: 20, left: 20),
                    width: MediaQuery.of(context).size.width,
                    height: 120,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20)),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            CameraPosition targetPosition = CameraPosition(
                              target: _contacts[index]["position"],
                              zoom: 15.0, // 원하는 줌 레벨
                            );

                            CameraUpdate cameraUpdate =
                                CameraUpdate.newCameraPosition(targetPosition);

                            _controller.animateCamera(cameraUpdate);
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.only(right: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  _contacts[index]['image'],
                                  width: 60,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  _contacts[index]["name"],
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    )),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        margin: EdgeInsets.only(left: 24, right: 12),
                        child: TextField(
                          focusNode: _focusNode,
                          style: TextStyle(color: Colors.white),
                          textAlignVertical: TextAlignVertical.bottom,
                          decoration: InputDecoration(
                            hintText: "Search",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.white.withOpacity(0.6),
                            filled: true,
                          ),
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12.0), // 버튼 모양 조절
                          border: Border.all(
                              color: Colors.white.withOpacity(0.6), width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0), // 내부 여백
                          child: Image.asset(
                            'assets/icons/icons8-close-480.png',
                            color: Colors.white.withOpacity(0.6),
                            width: 24.0, // 원하는 폭으로 조정
                            height: 24.0, // 원하는 높이로 조정
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24.0), // 간격 조절
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomInfoWindowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    final double triangleH = 10;
    final double triangleW = 30.0;
    final double width = size.width;
    final double height = size.height;

    final Path trianglePath = Path()
      ..moveTo(width / 2 - triangleW / 2, height)
      ..lineTo(width / 2, triangleH + height)
      ..lineTo(width / 2 + triangleW / 2, height)
      ..lineTo(width / 2 - triangleW / 2, height);

    canvas.drawPath(trianglePath, paint);
    final BorderRadius borderRadius = BorderRadius.circular(15);
    final Rect rect = Rect.fromLTRB(0, 0, width, height);
    final RRect outer = borderRadius.toRRect(rect);
    canvas.drawRRect(outer, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
