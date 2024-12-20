import 'dart:async';
import 'dart:convert';

import 'package:asgard_project/Util/uiwidget/CommonTextWidget.dart';
import 'package:asgard_project/productList/productList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../theme/color.dart';
import '../theme/string.dart';
import '../web_service/APIDirectory.dart';
import 'direction_model/directionModel.dart';

class MapDirectionWidgetOnRide extends StatefulWidget {
  ProductList? productList;
  Position? currentPosition;

  MapDirectionWidgetOnRide(
      {Key? key, required this.productList, required this.currentPosition})
      : super(key: key);

  @override
  _MapDirectionWidgetOnRideState createState() =>
      _MapDirectionWidgetOnRideState();
}

class _MapDirectionWidgetOnRideState extends State<MapDirectionWidgetOnRide>
    with TickerProviderStateMixin {
  GoogleMapController? mapController; //contrller for Google map
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = GoogleApiKey;
  String? _sessionToken;
  var uuid = const Uuid();
  Map<PolylineId, Polyline> polylines = {}; //polylines to show direction

  late LatLng pickupLocation = LatLng(
      (widget.currentPosition!.latitude != null)
          ? widget.currentPosition!.latitude
          : 22.650996848327292,
      (widget.currentPosition!.longitude != null)
          ? widget.currentPosition!.longitude
          : 75.83306003160679);

  /* late LatLng destinationLocation = LatLng(
      (widget.productList!.coordinates[0] != null)
          ? widget.productList!.coordinates[0]
          : 22.650996848327292,
      (widget.productList!.coordinates[1] != null)
          ? widget.productList!.coordinates[1]
          : 75.83306003160679);*/

  late LatLng destinationLocation =
      LatLng(23.002006477422324, 76.07645730410552);

  final List<Marker> markers = <Marker>[];
  final _mapMarkerSC = StreamController<List<Marker>>();

  StreamSink<List<Marker>> get mapMarkerSink => _mapMarkerSC.sink;

  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
  List<LatLng> polylineCoordinates = [];
  bool isLoading = true;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    //fetch direction polylines from Google API
    super.initState();
    _sessionToken = uuid.v4();
    addMarker();
    getDirections();
  }

  getDirections() async {
    String request =
        '$directionBaseURL?origin=${pickupLocation.latitude},${pickupLocation.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&mode=driving&transit_routing_preference=less_driving&sessiontoken=$_sessionToken&key=$googleAPiKey';
    var url = Uri.parse(request);
    print("url=====>${url}");
    dynamic response = await http.get(url);
    if (response != null && response != null) {
      if (response.statusCode == 200) {
        DirectionModel directionModel =
            DirectionModel.fromJson(json.decode(response.body));
        List<PointLatLng> pointLatLng = [];

        if (directionModel.routes.isNotEmpty) {
          for (var i = 0; i < directionModel.routes.length; i++) {
            for (var j = 0; j < directionModel.routes[i].legs.length; j++) {
              for (var k = 0;
                  k < directionModel.routes[i].legs[j].steps.length;
                  k++) {
                pointLatLng = polylinePoints.decodePolyline(
                    directionModel.routes[i].legs[j].steps[k].polyline.points);
                for (var point in pointLatLng) {
                  polylineCoordinates
                      .add(LatLng(point.latitude, point.longitude));
                }
              }
            }
            setState(() {
              addPolyLine(polylineCoordinates);
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load predictions');
      }
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppColor.themeColor,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
  }

  @override
  Widget build(BuildContext context) {
    final googleMap = StreamBuilder<List<Marker>>(
        stream: mapMarkerStream,
        builder: (context, snapshot) {
          return GoogleMap(
            //    mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              //innital position in map
              target: pickupLocation, //initial position
              zoom: 15.0, //initial zoom level
            ),
            polylines: Set<Polyline>.of(polylines.values),
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            mapToolbarEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: Set<Marker>.of(snapshot.data ?? []),
            padding: const EdgeInsets.all(8),
          );
        });

    return Scaffold(
      appBar: AppBar(title: CommonTextWidget(textval: directionScreen, colorval: Colors.white,
          sizeval: 16, fontWeight: FontWeight.bold),
      backgroundColor: AppColor.themeColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ), ),
      body: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : polylineCoordinates != null && polylineCoordinates.isNotEmpty
                  ? googleMap
                  : Center(
                      child: CommonTextWidget(
                          textval: "Route Not Found",
                          colorval: Colors.black,
                          sizeval: 14,
                          fontWeight: FontWeight.w600),
                    )
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (mapController != null) {
      mapController!.dispose();
    }
    super.dispose();
  }

  addMarker() async {
    var pickupMarker = Marker(
      //add start location marker
      markerId: MarkerId(pickupLocation.toString()),
      position: pickupLocation, //position of marker
      infoWindow: const InfoWindow(
        //popup info
        title: 'Pickup Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen), //Icon for Marker
    );

    var destinationMarker = Marker(
      //add start location marker
      markerId: MarkerId(destinationLocation.toString()),
      position: destinationLocation, //position of marker
      infoWindow: const InfoWindow(
        //popup info
        title: 'Destination Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed), //Icon for Marker
    );

    //Adding a delay and then showing the marker on screen
    await Future.delayed(const Duration(milliseconds: 500));

    markers.add(pickupMarker);
    markers.add(destinationMarker);
    mapMarkerSink.add(markers);
  }
}
