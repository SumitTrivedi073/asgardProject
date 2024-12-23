import 'package:asgard_project/Util/utility.dart';
import 'package:asgard_project/mapDIrection/mapDirectionWidget.dart';
import 'package:asgard_project/productList/productList.dart';
import 'package:asgard_project/theme/color.dart';
import 'package:asgard_project/theme/mapStyle.dart';
import 'package:asgard_project/theme/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:one_context/one_context.dart';

import 'Util/gpstracker.dart';
import 'Util/uiwidget/CommonTextWidget.dart';
import 'controllers/ProductController.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      builder: OneContext().builder,
      navigatorKey: OneContext().key,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late ProductController controller = Get.put(ProductController());
  final GPSTracker gpsTracker = GPSTracker();
  Position? currentPosition;
  LatLng? latlong = null;
  CameraPosition? _cameraPosition;
  GoogleMapController? mapController;
  bool isLocationEnabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }

    Utility().checkInternetConnectivity().then((connectionResult) {
      if (connectionResult) {
        getCurrentLocation();
      } else {
        Utility().InternetConnDialogue();
        Utility()
            .showInSnackBar(value: checkInternetConnection, context: context);
      }
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      isLocationEnabled = await gpsTracker.isLocationServiceEnabled();
       print('isLocationEnabled====>$isLocationEnabled');
      if (isLocationEnabled) {
        Position? position = await gpsTracker.getCurrentPosition();
        setState(() {
          currentPosition = position!;

          _cameraPosition = CameraPosition(
            bearing: 0,
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          );
          if (mapController != null) {
            mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_cameraPosition!));
          }
        });
      } else {
        gpsTracker.locationEnabledDialogue();
      }
    } catch (e) {
      await gpsTracker.getCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: CommonTextWidget(
              textval: appName,
              colorval: Colors.white,
              sizeval: 14,
              fontWeight: FontWeight.bold),
          backgroundColor: AppColor.themeColor),
      body: RefreshIndicator(
        backgroundColor: AppColor.themeColor,
        color: Colors.white,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
          controller.fetchProducts();
          setState(() {});
        }, // Trigger the refresh function;
        child: homeView(),
      ),
    );
    // Function that will be called when
    // user pulls the ListView downward
  }

  homeView() {
    return currentPosition != null &&
            currentPosition!.latitude.toString().isNotEmpty
        ? Obx(() {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: listView(),
                ),
                Expanded(
                  child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        MapView(),
                        curentLocationMarker(),
                        currentLocationBtn(),
                      ]),
                ),
              ],
            );
          })
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget listView() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: controller.products.isNotEmpty
            ? ListView.builder(
                itemCount: controller.products.length,
                itemBuilder: (context, index) {
                  return ListItem(controller.products[index]);
                },
              )
            : noProduct());
  }

  noProduct() {
    return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
            height: 100,
            child: Center(
              child: CommonTextWidget(
                textval: noProductAvailable,
                colorval: AppColor.blackColor,
                sizeval: 14,
                fontWeight: FontWeight.w600,
              ),
            )));
  }

  Widget ListItem(ProductList product) {
    final distance = Utility().calculateDistance(
        product.coordinates[0],
        product.coordinates[1],
        currentPosition!.latitude,
        currentPosition!.longitude);

    return GestureDetector(
        onTap: () {
          if (mapController != null) {
            mapController
                ?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              bearing: 0,
              target: LatLng(product.coordinates[0], product.coordinates[1]),
              zoom: 5.0,
            )));
          }
        },
        child: Card(
          elevation: 5,
          child: ListTile(
            leading: ClipOval(
                child: Utility().getNetworkImage(context, product.imageUrl)),
            title: CommonTextWidget(
                textval: product.title,
                colorval: AppColor.themeColor,
                sizeval: 16,
                fontWeight: FontWeight.bold),
            subtitle: CommonTextWidget(
                textval:
                    '${product.body}\nDistance: ${distance.toStringAsFixed(2)} km',
                colorval: AppColor.darkGrey,
                sizeval: 12,
                fontWeight: FontWeight.w400),
            trailing: IconButton(
              icon: const Icon(
                Icons.directions,
                color: AppColor.themeColor,
                size: 40,
              ),
              onPressed: () {
                // Action when button is pressed
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => MapDirectionWidget(
                              productList: product,
                              currentPosition: currentPosition,
                            )),
                    (Route<dynamic> route) => true);
              },
            ),
          ),
        ));
  }

  Widget MapView() {
    return GoogleMap(
          mapType: MapType.normal,
      initialCameraPosition: _cameraPosition!,
      onMapCreated: (GoogleMapController controller) {

        mapController = (controller);
        mapController
            ?.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition!));
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      zoomControlsEnabled: false,
      onCameraMove: (CameraPosition position) {
        latlong = LatLng(position.target.latitude, position.target.longitude);
      },
      markers: controller.products.map((product) {
        return Marker(
          markerId: MarkerId(product.id.toString()),
          position: LatLng(
            product.coordinates[0],
            product.coordinates[1],
          ),
          infoWindow: InfoWindow(
              title: product.title,
              snippet: product.body,
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => MapDirectionWidget(
                              productList: product,
                              currentPosition: currentPosition,
                            )),
                    (Route<dynamic> route) => true);
              }),
        );
      }).toSet(),
    );
  }

  Widget curentLocationMarker() {
    return Center(
        child: SvgPicture.asset(
      "assets/svg/currentMarker.svg",
      width: 20,
      height: 20,
    ));
  }

  Widget currentLocationBtn() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 140),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton(
            backgroundColor: AppColor.themeColor,
            onPressed: () {
              setState(() {
                getCurrentLocation();
              });
            },
            child: const Icon(
              Icons.my_location_outlined,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has resumed, check location status
      getCurrentLocation();
      controller = Get.put(ProductController());
      setState(() {});
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
}
