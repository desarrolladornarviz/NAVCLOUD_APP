import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'createProducts_screen.dart'; // Asegúrate de importar la pantalla CreateProductsScreen

class ProductsScreen extends StatefulWidget {
  final int companyId;

  ProductsScreen({required this.companyId});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<dynamic>> _products;

  @override
  void initState() {
    super.initState();
    _products = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = 'http://192.168.100.34:8000/api/v1/api-productos/${widget.companyId}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response body: ${response.body}'); // Asegúrate de que el JSON completo se imprima

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('productos')) {
            final productos = data['productos'];
            if (productos is List<dynamic>) {
              return productos;
            } else {
              throw Exception('Productos data is not a list');
            }
          } else {
            throw Exception('Invalid JSON structure');
          }
        } catch (e) {
          throw FormatException('Failed to parse JSON: $e');
        }
      } else {
        throw Exception('Failed to load productos, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch productos');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Productos'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay productos disponibles.'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['nombre']),
                subtitle: Text('Precio: ${product['precio_unitario']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateProductsScreen(
                        companyId: widget.companyId,
                        product: product, // Pasar los datos del producto
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
