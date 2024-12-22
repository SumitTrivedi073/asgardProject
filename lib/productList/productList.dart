// To parse this JSON data, do
//
//     final productList = productListFromJson(jsonString);

import 'dart:convert';

List<ProductList> productListFromJson(String str) => List<ProductList>.from(json.decode(str).map((x) => ProductList.fromJson(x)));

String productListToJson(List<ProductList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductList {
  String imageUrl;
  List<double> coordinates;
  String id;
  String title;
  String body;
  String userId;

  ProductList({
    required this.imageUrl,
    required this.coordinates,
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
  });

  factory ProductList.fromJson(Map<String, dynamic> json) => ProductList(
    imageUrl: json["imageUrl"],
    coordinates: List<double>.from(json["coordinates"].map((x) => x?.toDouble())),
    id: json["id"],
    title: json["title"],
    body: json["body"],
    userId: json["userId"],
  );

  Map<String, dynamic> toJson() => {
    "imageUrl": imageUrl,
    "coordinates": List<dynamic>.from(coordinates.map((x) => x)),
    "id": id,
    "title": title,
    "body": body,
    "userId": userId,
  };
}
