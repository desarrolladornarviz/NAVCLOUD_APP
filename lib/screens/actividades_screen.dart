import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'invoiceDetail_screen.dart';
import 'createInvoice_screen.dart';
import 'package:fact_nav/config.dart'; 

class ActividadesScreen extends StatefulWidget {
  final int companyId;

  ActividadesScreen({required this.companyId});

  @override
  _ActividadesScreenState createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
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
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is Map<String, dynamic> && data.containsKey('facturas')) {
            List<dynamic> facturas = data['facturas'];

            // Obtener la fecha actual y la fecha límite (7 días atrás)
            DateTime now = DateTime.now();
            DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

            // Filtrar facturas de los últimos 7 días
            facturas = facturas.where((factura) {
              String fechaString = factura['fecha'] ?? ''; // Asegúrate de que 'fecha' esté en el formato correcto
              DateTime fechaFactura;
              try {
                fechaFactura = DateTime.parse(fechaString); // Intenta analizar la fecha
              } catch (e) {
                print('Error parsing date: $e');
                return false; // No incluir facturas con fecha inválida
              }
              return fechaFactura.isAfter(sevenDaysAgo) && fechaFactura.isBefore(now);
            }).toList();

            // Ordenar las facturas por ID
            facturas.sort((a, b) {
              int idA = int.parse(a['id'].toString());
              int idB = int.parse(b['id'].toString());
              return idB.compareTo(idA);
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
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Reporte de Actividades',
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
            return Center(child: Text('No se encontraron facturas'));
          } else {
            final facturas = _filteredFacturas;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Facturas de los Últimos 7 Días',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: facturas.length,
                    itemBuilder: (context, index) {
                      final invoice = facturas[index];
                      final canVer = invoice['PERMISO_VER_RIDE'] == true;
                      final canEdit = invoice['PERMISO_EDITAR'] == true;
                      final canDelete = invoice['PERMISO_ELIMINAR'] == true;
                      final canAuthorize = invoice['PERMISO_AUTORIZAR'] == true;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cliente: ${invoice['cliente_nombre']}',
                                style: TextStyle(color: Colors.blueGrey[600]),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Fecha: ${invoice['fecha']}',
                                style: TextStyle(color: Colors.blueGrey[600]),
                              ),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total: \$${invoice['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[700],
                                  fontSize: 15.0,
                                ),
                              ),
                            
                             
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
