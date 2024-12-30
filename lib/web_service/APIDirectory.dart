import 'package:flutter/foundation.dart';

const scheme = 'http';
const host = 'localhost';
const port = '5001';
const mobileHost = '192.168.29.211';

const webBaseUrl = '$scheme://$host:$port';
const mobileBaseUrl = '$scheme://$mobileHost:$port';

const productionUrl = 'https://prcddzpsk5p33eazh5ykzbj4ra0xwyhk.lambda-url.eu-west-2.on.aws/';
const directionBaseURL = 'https://maps.googleapis.com/maps/api/directions/json';


getBaseURL() {
  String baseUrl = productionUrl;
  return baseUrl;
}

getproductList() {
  return Uri.parse('${getBaseURL()}');
}

