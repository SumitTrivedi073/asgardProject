import 'dart:async';
import 'dart:convert';

import 'package:asgard_project/Util/uiwidget/CommonTextWidget.dart';
import 'package:asgard_project/Util/utility.dart';
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

class MapDirectionWidget extends StatefulWidget {
  ProductList? productList;
  Position? currentPosition;

  MapDirectionWidget(
      {Key? key, required this.productList, required this.currentPosition})
      : super(key: key);

  @override
  _MapDirectionWidgetState createState() => _MapDirectionWidgetState();
}

class _MapDirectionWidgetState extends State<MapDirectionWidget>with WidgetsBindingObserver {
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

  late LatLng destinationLocation = LatLng(
      (widget.productList!.coordinates[0] != null)
          ? widget.productList!.coordinates[0]
          : 22.650996848327292,
      (widget.productList!.coordinates[1] != null)
          ? widget.productList!.coordinates[1]
          : 75.83306003160679);

/*  late LatLng destinationLocation =
      LatLng(22.991676281686242, 76.08486752671082);*/

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
    super.initState();
    WidgetsBinding.instance.addObserver(this);

   init();
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
      appBar: AppBar(
          title: CommonTextWidget(
              textval: directionScreen,
              colorval: Colors.white,
              sizeval: 14,
              fontWeight: FontWeight.bold),
          // TextStyle

          backgroundColor: AppColor.themeColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),),
      body: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : polylineCoordinates != null && polylineCoordinates.isNotEmpty
                  ? googleMap
                  : Container(
                      child: Stack(
                        children: [
                          googleMap,
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              color: AppColor.themeColor,
                              height: 50,
                              child: Center(child: CommonTextWidget(
                                  textval: routeNotFound,
                                  colorval: AppColor.whiteColor,
                                  sizeval: 14,
                                  fontWeight: FontWeight.bold),),
                            ),
                          )
                        ],
                      ),
                    )
        ],
      ),
    );
  }

  addMarker() async {
    var pickupMarker = Marker(
      //add start location marker
      markerId: MarkerId(pickupLocation.toString()),
      position: pickupLocation, //position of marker
      infoWindow:  InfoWindow(
        //popup info
        title: pickupLocation_,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen), //Icon for Marker
    );

    var destinationMarker = Marker(
      //add start location marker
      markerId: MarkerId(destinationLocation.toString()),
      position: destinationLocation, //position of marker
      infoWindow:  InfoWindow(
        //popup info
        title: destLocation,
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

  getDirections() async {
    String request =
        '$directionBaseURL?origin=${pickupLocation.latitude},${pickupLocation.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&mode=driving&transit_routing_preference=less_driving&sessiontoken=$_sessionToken&key=$googleAPiKey';
    var url = Uri.parse(request);
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
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has resumed, check location status
      init();
      setState(() {

      });
    }
  }

  @override
  void dispose() {
    if (mapController != null) {
      mapController!.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void init() {
    _sessionToken = uuid.v4();
    addMarker();
    Utility().checkInternetConnectivity().then((connectionResult) {
      if (connectionResult) {
        getDirections();
      } else {
        Utility().InternetConnDialogue();
        Utility()
            .showInSnackBar(value: checkInternetConnection, context: context);
      }
    });
  }
}
