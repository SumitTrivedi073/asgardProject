
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/color.dart';
import '../theme/string.dart';

class Utility {

  bool isActiveConnection = false;
   Future<bool> checkInternetConnection() async {

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isActiveConnection = true;
      return  Future<bool>.value(isActiveConnection);
      }
    } on SocketException catch (_) {
      isActiveConnection = false;
      return  Future<bool>.value(isActiveConnection);
    }
    return  Future<bool>.value(isActiveConnection);
  }

 void showInSnackBar({required String value,required context}) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(value),
       duration: const Duration(milliseconds: 3000),
     ),
   );
 }
  void showToast(String toast_msg) {
    Fluttertoast.showToast(
        msg: toast_msg,
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 9);
  }

  getNetworkImage(context, path) {
    if (path != null && path != null) {
      return Image.network(encodeImgURLString(path),
          errorBuilder: (context, error, stackTrace) {
            return pleaceholderImage();
          }, height: 50, width: 50, fit: BoxFit.cover);
    }else{
      return pleaceholderImage();
    }
  }

  String encodeImgURLString(tmp) {
    String endStr =
    tmp != null && tmp != '' ? Uri.encodeFull(tmp).trim() : 'assets/images/asgard_logo.png';
    return endStr;
  }
  double calculateDistance(double lat, double lng,double currentLat, double currentLng) {

    print('userLocation====>${currentLat}');
    print('userLocation====>${currentLng}');
    print('lat====>${lat}');
    print('lng====>${lng}');
    return Geolocator.distanceBetween(
      currentLat,
      currentLng,
      lat,
      lng,
    ) / 1000; // Distance in kilometers

  }

  pleaceholderImage() {
     return Image.asset(
         'assets/images/asgard_logo.png',
         height: 50,
         width: 50,
         fit: BoxFit.cover
     );
  }

}