// To parse this JSON data, do
//
//     final productList = productListFromJson(jsonString);

import 'dart:convert';

List<ProductList> productListFromJson(String str) => List<ProductList>.from(json.decode(str).map((x) => ProductList.fromJson(x)));

String productListToJson(List<ProductList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductList {
  int userId;
  int id;
  String title;
  String body;
  List<double> coordinates;
  String imageUrl;
   String Coordinate = '0.0';
  ProductList({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    required this.coordinates,
    required this.imageUrl,
  });


  factory ProductList.fromJson(Map<String, dynamic> json) => ProductList(
    userId: json["userId"]??'',
    id: json["id"]??'',
    title: json["title"]??'',
    body: json["body"]??'',
    coordinates: json["coordinates"]!=null?List<double>.from(json["coordinates"].map((x) => x?.toDouble())):[],
    imageUrl: json["imageUrl"]??'',
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "id": id,
    "title": title,
    "body": body,
    "coordinates": List<dynamic>.from(coordinates.map((x) => x)),
    "imageUrl": imageUrl,
  };
}
