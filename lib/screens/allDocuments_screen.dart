import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'invoiceDetail_screen.dart'; // Asegúrate de importar el archivo correcto

class AllDocumentsScreen extends StatefulWidget {
  final int companyId;

  AllDocumentsScreen({required this.companyId});

  @override
  _AllDocumentsScreenState createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends State<AllDocumentsScreen> {
  late Future<List<dynamic>> _facturas;
  List<dynamic> _facturasList = [];
  List<dynamic> _filteredFacturas = [];
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _facturas = fetchFacturas();
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<dynamic>> fetchFacturas() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';

  try {
    final response = await http.get(
      Uri.parse('http://192.168.100.34:8000/api/v1/company/${widget.companyId}/documentos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type' : 'application/json',
      },
    );

    // Verificar el estado de la respuesta
    if (response.statusCode == 200) {
      try {

        final data = json.decode(response.body);

        // Verificar que la estructura JSON es correcta
        if (data is Map<String, dynamic> && data.containsKey('facturas')) {
          List<dynamic> facturas = data['facturas'];

          // Ordenar las facturas por ID en orden descendente
          facturas.sort((a, b) {
            int idA = int.parse(a['id'].toString());
            int idB = int.parse(b['id'].toString());
            return idB.compareTo(idA); // Ordena de forma descendente
          });

          setState(() {
            _facturasList = facturas;
            _filteredFacturas = facturas;
          });
          return facturas;
        } else {
          throw Exception('Invalid JSON structure: Missing "facturas" key');
        }
      } catch (e) {
        print('Failed to parse JSON: $e');
        throw Exception('Failed to parse JSON');
      }
    } else {
      print('Failed to load documents: ${response.statusCode}');
      throw Exception('Failed to load documents');
    }
  } catch (e) {
    print('Error fetching facturas: $e');
    throw Exception('Failed to load documents');
  }
}


  Future<http.Response> retryHttpRequest(Future<http.Response> Function() request, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await request();
        if (response.statusCode == 200) {
          return response;
        }
      } catch (e) {
        if (attempt == retries - 1) rethrow; // Si es el último intento, lanza la excepción
      }
    }
    throw Exception('Failed after $retries retries');
  }

  void _onSearchChanged() {
    setState(() {
      _filteredFacturas = _facturasList.where((invoice) {
        return invoice['numero_documento'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
               invoice['cliente_nombre'].toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white), // Cambia el color del texto a blanco
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(color: Colors.white70), // Color del texto del hint
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Historial de Facturas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredFacturas = _facturasList;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
  future: _facturas,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('No invoices found'));
    } else {
      final facturas = _filteredFacturas;

      return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: facturas.length,
        itemBuilder: (context, index) {
          final invoice = facturas[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            child: ListTile(
              leading: Icon(
                Icons.receipt,
                color: Colors.blueGrey[800],
              ),
              title: Text(
                'Número Documento: ${invoice['numero_documento']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              subtitle: Text(
                'Cliente: ${invoice['cliente_nombre']}',
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              trailing: Text(
                'Total: \$${invoice['total'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                  fontSize: 15.0,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailScreen(invoice: invoice),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  },
)

    );
  }
}
