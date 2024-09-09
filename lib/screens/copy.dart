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
Future<void> deleteFactura(int facturaId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';

  final response = await http.delete(
    Uri.parse('http://192.168.100.34:8000/api/v1/factura/$facturaId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    print('Factura eliminada exitosamente');
    print('Response body: ${response.body}'); // Imprime el contenido de la respuesta
  } else {
    print('Error al eliminar factura: ${response.statusCode}');
    print('Response body: ${response.body}'); // Imprime el contenido de la respuesta
  }
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

            /* Imprimir todos los atributos de cada factura incluyendo permisos */
            for (var factura in facturas) {
              print('Factura:');
              factura.forEach((key, value) {
                print('$key: $value');
              });

              // Imprimir los permisos si existen
              print('Permisos:');
              
              print('PERMISO_EDITAR: ${factura['PERMISO_EDITAR']}');
              print('PERMISO_ELIMINAR: ${factura['PERMISO_ELIMINAR']}');
              print('PERMISO_AUTORIZAR: ${factura['PERMISO_AUTORIZAR']}');
              print('PERMISO_ENVIAR_MAIL: ${factura['PERMISO_ENVIAR_MAIL']}');
              print(''); // Línea en blanco para separar las facturas
            }

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

  Color getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'creada':
        return const Color.fromARGB(255, 45, 81, 243);
      case 'autorizado':
        return Colors.green;
      case 'no autorizado':
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey; // Color predeterminado si el estado no coincide
    }
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
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          ListTile(
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
                              ],
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
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  icon: Icon(Icons.visibility),
                                  label: Text(
                                    'Ver',
                                    style: TextStyle(fontSize: 12.0), // Ajusta el tamaño de la fuente
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InvoiceDetailScreen(invoice: invoice),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  icon: Icon(Icons.edit),
                                  label: Text(
                                    'Editar',
                                    style: TextStyle(fontSize: 12.0), // Ajusta el tamaño de la fuente
                                  ),
                                  onPressed: () {
                                    // Lógica para editar la factura
                                    print('Editar ${invoice['numero_documento']}');
                                  },
                                ),
                              ),
                            Expanded(
                              child: TextButton.icon(
                                icon: Icon(Icons.delete),
                                label: Text(
                                  'Eliminar',
                                  style: TextStyle(fontSize: 12.0), // Ajusta el tamaño de la fuente
                                ),
                                onPressed: () async {
                                  final confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirmar eliminación'),
                                      content: Text('¿Estás seguro de que quieres eliminar esta factura?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancelar'),
                                          onPressed: () => Navigator.of(context).pop(false),
                                        ),
                                        TextButton(
                                          child: Text('Eliminar'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete ?? false) {
                                    try {
                                      // Eliminar factura
                                      await deleteFactura(invoice['id']);

                                      // Mostrar mensaje de éxito
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Factura eliminada correctamente'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      // Refrescar la lista de facturas
                                      setState(() {
                                        _facturas = fetchFacturas(); // Llama de nuevo a fetchFacturas para actualizar la lista
                                      });
                                    } catch (e) {
                                      // Mostrar mensaje de error
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al eliminar la factura'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                              Expanded(
                                child: TextButton.icon(
                                  icon: Icon(Icons.check),
                                  label: Text(
                                    'Autorizar',
                                    style: TextStyle(fontSize: 10.0), // Ajusta el tamaño de la fuente
                                  ),
                                  onPressed: () {
                                    // Lógica para autorizar la factura
                                    print('Autorizar ${invoice['numero_documento']}');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${invoice['estado']}',
                            style: TextStyle(
                              color: getColorForStatus(invoice['estado']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

}