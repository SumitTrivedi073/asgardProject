// To parse this JSON data, do
//
//     final directionModel = directionModelFromJson(jsonString);

import 'dart:convert';
import 'route.dart';

DirectionModel directionModelFromJson(String str) => DirectionModel.fromJson(json.decode(str));

String directionModelToJson(DirectionModel data) => json.encode(data.toJson());

class DirectionModel {
  DirectionModel({
    required this.routes,
    required this.status,
  });

  List<Route> routes;
  String status;

  factory DirectionModel.fromJson(Map<String, dynamic> json) => DirectionModel(
    routes: json["routes"]!=null&& json["routes"].toString().isNotEmpty?List<Route>.from(json["routes"].map((x) => Route.fromJson(x))):[],
    status: json["status"] !=""? json["status"]:"",
  );

  Map<String, dynamic> toJson() => {
   "routes": List<dynamic>.from(routes.map((x) => x.toJson())),
    "status": status,
  };
}















