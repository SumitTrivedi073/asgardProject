import 'dart:convert' as convert;

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../Util/gpstracker.dart';
import '../Util/utility.dart';
import '../productList/productList.dart';
import '../theme/string.dart';
import '../web_service/APIDirectory.dart';

class ProductController extends GetxController {
  var products = <ProductList>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
        fetchProducts();
  }

  Future<void> fetchProducts() async {
    products = <ProductList>[].obs;
    isLoading(true);
    try {
      final response = await http.get(getproductList());
      if (response.statusCode == 200) {
        print('response=====>${response.body.toString()}');
        final List<dynamic> data = convert.jsonDecode(response.body);
        products.value =
            data.map((json) => ProductList.fromJson(json)).toList();
      } else {
     //   Get.snackbar('Error', 'Failed to fetch products');
        isLoading(false);
      }
    } catch (e) {
     // Get.snackbar('Error', 'Failed to fetch products');
      isLoading(false);
    } finally {
      isLoading(false);
    }
  }
}
