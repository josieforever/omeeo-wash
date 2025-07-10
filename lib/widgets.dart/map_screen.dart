import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng omeeoLocation = LatLng(5.6288569, -0.2725429); // Omeeo's coords

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: omeeoLocation,
            zoom: 16.0,
          ),
          markers: {
            Marker(
              markerId: MarkerId('omeeo'),
              position: omeeoLocation,
              infoWindow: InfoWindow(title: 'Omeeo Wash'),
            ),
          },
        ),
      ),
    );
  }
}
