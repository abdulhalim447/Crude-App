import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_api_practice/product_model.dart';
import 'package:flutter_api_practice/update_product_screen.dart';
import 'package:http/http.dart' as http;
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _getProductListInProgress = false;
  List<ProductModel> productList = [];

  @override
  void initState() {
    super.initState();
    _getProductList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awesome Store'),
      ),
      body: RefreshIndicator(
        onRefresh: _getProductList,
        child: Visibility(
          visible: !_getProductListInProgress,
          replacement: const Center(
            child: CircularProgressIndicator(),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: productList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              return _buildProductItem(productList[index]);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) {
            _getProductList();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _getProductList() async {
    setState(() {
      _getProductListInProgress = true;
    });
    productList.clear();
    const String productListUrl = 'https://crud.teamrabbil.com/api/v1/ReadProduct';
    Uri uri = Uri.parse(productListUrl);
    http.Response response = await http.get(uri);
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final jsonProductList = decodedData['data'];
      for (Map<String, dynamic> json in jsonProductList) {
        ProductModel productModel = ProductModel.fromJson(json);
        productList.add(productModel);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Get product list failed! Try again.')),
      );
    }

    setState(() {
      _getProductListInProgress = false;
    });
  }

  Widget _buildProductItem(ProductModel product) {
    return GestureDetector(
      onLongPress: () {
        _showContextMenu(product);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Stack(
                  children: [
                    Center(child: CircularProgressIndicator()),
                    Image.network(
                      product.image ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 60);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.productName ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Unit Price: ${product.unitPrice}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Quantity: ${product.quantity}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total Price: ${product.totalPrice}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(ProductModel product) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateProductScreen(product: product),
                    ),
                  );
                  if (result == true) {
                    _getProductList();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(product.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: const Text('Are you sure that you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteProduct(productId);
                Navigator.pop(context);
              },
              child: const Text('Yes, delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    setState(() {
      _getProductListInProgress = true;
    });
    String deleteProductUrl = 'https://crud.teamrabbil.com/api/v1/DeleteProduct/$productId';
    Uri uri = Uri.parse(deleteProductUrl);
    http.Response response = await http.delete(uri);
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      _getProductList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete product failed! Try again.')),
      );
    }

    setState(() {
      _getProductListInProgress = false;
    });
  }
}
