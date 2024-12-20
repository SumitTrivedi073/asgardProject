import 'package:flutter/foundation.dart';

const scheme = 'http';
const host = 'localhost';
const port = '5001';
const mobileHost = '192.168.29.211';

const webBaseUrl = '$scheme://$host:$port';
const mobileBaseUrl = '$scheme://$mobileHost:$port';

const productionUrl = 'https://mocki.io/v1/6655ddaf-5212-437a-a544-3d2a418985f6';
const directionBaseURL = 'https://maps.googleapis.com/maps/api/directions/json';


getBaseURL() {
  String baseUrl = productionUrl;
  return baseUrl;
}

getproductList() {
  return Uri.parse('${getBaseURL()}');
}

