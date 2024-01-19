import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng destination = LatLng(37.33429383, -122.06600055);

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  double markerSize = 48.0; // Initial marker size
  String mapTheme = '';

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)),
            "assets/Pin_destination.png")
        .then(
      (icon) {
        destinationIcon = icon;
      },
    );
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(markerSize, markerSize)),
            "assets/Badge.png")
        .then(
      (icon) {
        currentLocationIcon = icon;
      },
    );
  }

  void initState() {
    super.initState();
    DefaultAssetBundle.of(context)
        .loadString('assets/maptheme/sliver_theme.json')
        .then((value) {
      mapTheme = value;
    });
  }

  void _onCameraMove(CameraPosition position) {
    // Update marker size based on zoom level
    setState(() {
      markerSize = 192.0 * position.zoom; // Adjust the scale factor as needed
    });
    setCustomMarkerIcon(); // Update marker icons with the new size
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          controller.setMapStyle(mapTheme);
          _controller.complete(controller);
          setCustomMarkerIcon();
        },
        onCameraMove: _onCameraMove, // Add onCameraMove callback
        initialCameraPosition:
            CameraPosition(target: sourceLocation, zoom: 14.5),
        markers: {
          Marker(
            markerId: MarkerId("source"),
            icon: currentLocationIcon,
            position: sourceLocation,
          ),
          Marker(
            markerId: MarkerId("destination"),
            icon: destinationIcon,
            position: destination,
          ),
        },
      ),
    );
  }
}
