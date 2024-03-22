// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
// import 'package:rive/rive.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: AnimateMap(),
//     );
//   }
// }

// class AnimateMap extends StatefulWidget {
//   const AnimateMap({Key? key}) : super(key: key);

//   @override
//   _AnimateMapState createState() => _AnimateMapState();
// }

// class _AnimateMapState extends State<AnimateMap> {
//   GoogleMapController? _mapController;
//   LocationData? _currentLocation;
//   Set<Marker> _markers = {};
//   RiveAnimationController? _riveController;

//   @override
//   void initState() {
//     super.initState();
//     _loadRiveFile();
//     _getLocation();
//   }

//   Future<void> _loadRiveFile() async {
//     final bytes = await DefaultAssetBundle.of(context)
//         .load('assets/animations/active_status-2.riv');
//     final file = RiveFile.import(bytes);
//     final controller = SimpleAnimation('Animation');
//     file.mainArtboard!.addController(controller);
//     setState(() {
//       _riveController = controller;
//     });
//   }

//   Future<void> _getLocation() async {
//     final location = Location();
//     try {
//       LocationData currentLocation = await location.getLocation();
//       setState(() {
//         _currentLocation = currentLocation;
//         _addMarkerWithRiveAnimation(
//           LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
//         );
//       });
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   void _addMarkerWithRiveAnimation(LatLng latLng) {
//     if (_riveController != null) {
//       setState(() {
//         _markers.clear();
//         _markers.add(
//           Marker(
//             markerId: MarkerId(latLng.toString()),
//             position: latLng,
//           ),
//         );
//       });

//       // Google Map의 카메라를 현재 위치로 이동
//       _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

//       // 애니메이션을 시작
//       if (_riveController != null && _riveController!.isActive) {
//         // 애니메이션을 초기화하고 재생
//         if (_riveController!.init(null)) {
//           _riveController!.isActive = true;
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GoogleMap(
//         onMapCreated: (controller) {
//           _mapController = controller;
//         },
//         initialCameraPosition: CameraPosition(
//           target: LatLng(37.7749, -122.4194),
//           zoom: 12.0,
//         ),
//         markers: _markers,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _getLocation();
//         },
//         child: Icon(Icons.my_location),
//       ),
//     );
//   }
// }
