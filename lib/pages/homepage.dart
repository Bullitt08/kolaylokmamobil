import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Homepage extends StatefulWidget{
  @override
  State<Homepage> createState()=> _HomepageState();
}

class _HomepageState extends State<Homepage>{
  LatLng? userLocation;
  MapController mapController = MapController();
  double zoomLevel = 13.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen konumunuzu açınız")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konum izni gerekli.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum izni gerekli.")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (mounted) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (userLocation != null) {
          mapController.move(userLocation!, 13.0);
        }
      });
    }
  }

  void _zoomIn() {
    setState(() {
      zoomLevel++;
      if (userLocation != null) {
        mapController.move(userLocation!, zoomLevel);
      }
    });
  }

  void _zoomOut() {
    setState(() {
      zoomLevel--;
      if (userLocation != null) {
        mapController.move(userLocation!, zoomLevel);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: userLocation ?? LatLng(0.0, 0.0),
            initialZoom: zoomLevel,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                if (userLocation != null)
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: userLocation!,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
              ],
            ),
          ],
        ),

        Positioned(
          bottom: 30.0,
          right: 10.0,
          child: FloatingActionButton(
            onPressed: () {
              _getCurrentLocation();
            },
            child: const Icon(Icons.my_location),
            backgroundColor: Colors.blueAccent,
          ),
        ),

        Positioned(
          bottom: 100.0,
          right: 10.0,
          child: FloatingActionButton(
            onPressed: _zoomIn,
            child: const Icon(Icons.zoom_in),
            backgroundColor: Colors.blueAccent,
          ),
        ),

        Positioned(
          bottom: 170.0,
          right: 10.0,
          child: FloatingActionButton(
            onPressed: _zoomOut,
            child: const Icon(Icons.zoom_out),
            backgroundColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}