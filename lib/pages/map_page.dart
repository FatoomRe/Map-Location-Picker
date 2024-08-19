import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Controller for location services
  final loc.Location _locationController = loc.Location();
  // Variable to store the address of the picked location
  String? _locationText;
  // Completer to manage the Google Map controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //------------------------------------------------------------------------- APP BAR
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 179, 99),
        title: const Text(
          "Location Picker",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      //------------------------------------------------------------------------- BODY
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/gmp.png"),
          // Button to open the map and pick a location
          ElevatedButton(
            onPressed: _openMap,
            child: const Text("Pick Location"),
          ),
          const SizedBox(height: 20),
          // Display the selected location's address or a default message inside a TextField
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: TextEditingController(
                text: _locationText != null
                    ? "Selected Location:\n$_locationText"
                    : "No location selected",
              ),
              textAlign: TextAlign.center,
              readOnly: true,
              maxLines: null, // Allow text to adjust to new lines
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 196, 255, 206),
                contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // Increase height
              ),
            ),
          ),
        ],
      ),
    );
  }

  //---------------------------------------------------------------------------------- METHODS
  // Method to open the map and pick a location
  Future<void> _openMap() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    // Check if location services are enabled
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check if location permissions are granted
    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // Get the current location
    loc.LocationData _locationData = await _locationController.getLocation();

    // Set the initial position for the map
    LatLng initialPosition = LatLng(
      _locationData.latitude!,
      _locationData.longitude!,
    );

    // Navigate to the map picker page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialPosition: initialPosition,
          onLocationPicked: (LatLng location) async {
            // Get the address from the picked location
            String address = await _getAddressFromLatLng(location);
            setState(() {
              _locationText = address;
            });
          },
        ),
      ),
    );
  }

  // Method to get the address from latitude and longitude
  Future<String> _getAddressFromLatLng(LatLng location) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
    }
    return "No address available";
  }
}

// Widget for the map picker page
class MapPickerPage extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng) onLocationPicked;

  const MapPickerPage({
    super.key,
    required this.initialPosition,
    required this.onLocationPicked,
  });

  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _pickedLocation;
  LatLng? _currentCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        actions: [
          // Button to confirm the picked location
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_pickedLocation != null) {
                widget.onLocationPicked(_pickedLocation!);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            // Update the current camera position when the map is moved
            onCameraMove: (CameraPosition position) {
              _currentCameraPosition = position.target;
            },
            // Set the picked location when the camera movement stops
            onCameraIdle: () {
              setState(() {
                _pickedLocation = _currentCameraPosition;
              });
            },
            // Display a marker at the picked location
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId("pickedLocation"),
                      position: _pickedLocation!,
                    ),
                  }
                : {},
          ),
          // Center marker icon
          // Center(
          //   child: Icon(
          //     Icons.location_pin,
          //     color: Colors.red,
          //     size: 40,
          //   ),
          // ),
        ],
      ),
    );
  }
}