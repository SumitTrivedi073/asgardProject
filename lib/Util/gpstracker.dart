import 'package:app_settings/app_settings.dart';
import 'package:asgard_project/Util/uiwidget/CommonTextWidget.dart';
import 'package:asgard_project/Util/utility.dart';
import 'package:asgard_project/theme/color.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:one_context/one_context.dart';

class GPSTracker {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {

    return await Geolocator.isLocationServiceEnabled();
  }

  // Request permission for location access
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get the current position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      Utility().showToast("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        Utility().showToast("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Utility().showToast("Location permissions are permanently denied. Please enable them in settings.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Stream position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance (in meters) for updates
      ),
    );
  }

  void locationEnabledDialogue() {
    OneContext().dialog.showDialog(
        builder: (context) => AlertDialog(
          title: Text("Location Disabled"),
          content: Text(
            "Location services are disabled. Please enable them to continue.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: CommonTextWidget(textval:"Cancel",colorval: AppColor.darkGrey,sizeval: 12,fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings(type: AppSettingsType.location);// Close the dialog
                // Optionally navigate to settings
              },
              child: CommonTextWidget(textval: "Enable",colorval: AppColor.themeColor,sizeval: 12,fontWeight: FontWeight.bold,),
            ),
          ],
        ),
      );
  }


}