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

  Future<bool> deleteFactura(int facturaId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';

  try {
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
      return true; // Indica éxito
    } else {
      print('Error al eliminar factura: ${response.statusCode}');
      print('Response body: ${response.body}'); // Imprime el contenido de la respuesta
      return false; // Indica fallo
    }
  } catch (e) {
    print('Error al eliminar factura: $e');
    return false; // Indica fallo debido a excepción
  }
}

Future<void> _authorizeInvoice() async {
   final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
    final url = 'http://192.168.100.34:8000/api/v1/autorizar';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          // Agrega headers si tu API los requiere, como autorización
        },
        body: jsonEncode({
          'id': ['id'], // Incluye cualquier dato necesario en el cuerpo
        }),
      );

      if (response.statusCode == 200) {
        // API respondió con éxito
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          // Acciones si la respuesta es exitosa
          print('Factura autorizada con éxito');
        } else {
          // Manejo de errores si la respuesta no es exitosa
          print('No se pudo autorizar la factura');
        }
      } else {
        // Manejo de errores para respuestas no exitosas
        print('Error al autorizar la factura: ${response.statusCode}');
      }
    } catch (error) {
      // Manejo de excepciones
      print('Error: $error');
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

            /* Imprimir todos los atributos de cada factura incluyendo permisos 
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
            }*/

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
                final canVer = invoice['PERMISO_VER_RIDE'] == true;
                final canEdit = invoice['PERMISO_EDITAR'] == true;
                final canDelete = invoice['PERMISO_ELIMINAR'] == true;
                final canAuthorize = invoice['PERMISO_AUTORIZAR'] == true;

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
                         if (canEdit || canDelete || canAuthorize || canVer) 
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Wrap(
                                  spacing: 8.0, // Espacio entre elementos
                                  runSpacing: 4.0, // Espacio entre filas de elementos
                                  children: [
                                    if (canVer)
                                      TextButton.icon(
                                        icon: Icon(Icons.remove_red_eye, size: 14.0, color: Colors.blueGrey[800]), // Tamaño del ícono y color
                                        label: Text(
                                          'Ver',
                                          style: TextStyle(fontSize: 12.0, color: Colors.blueGrey[800]), // Tamaño del texto y color
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => InvoiceDetailScreen(invoice: invoice),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Tamaño del botón
                                          backgroundColor: Colors.transparent, // Fondo transparente
                                          side: BorderSide(color: Colors.blueGrey[300]!, width: 1), // Borde del botón
                                        ),
                                      ),
                                    if (canEdit)
                                      TextButton.icon(
                                        icon: Icon(Icons.edit, size: 14.0, color: Colors.blueGrey[800]),
                                        label: Text(
                                          'Editar',
                                          style: TextStyle(fontSize: 12.0, color: Colors.blueGrey[800]),
                                        ),
                                        onPressed: () {
                                          print('Editar ${invoice['numero_documento']}');
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(color: Colors.blueGrey[300]!, width: 1),
                                        ),
                                      ),
                                    if (canDelete)
                                      TextButton.icon(
                                        icon: Icon(Icons.delete, size: 14.0, color: Colors.red[800]),
                                        label: Text(
                                          'Eliminar',
                                          style: TextStyle(fontSize: 12.0, color: Colors.red[800]),
                                        ),
                                        onPressed: () async {
                                          final shouldDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Confirmar Eliminación'),
                                              content: Text('¿Estás seguro de que deseas eliminar esta factura?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.white, // Color del texto
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.red, // Color de fondo
                                                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0), // Tamaño del botón
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8.0), // Bordes redondeados
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (shouldDelete == true) {
                                            // Espera el resultado de la eliminación
                                            final isDeleted = await deleteFactura(invoice['id']);

                                            // Muestra el mensaje adecuado en el SnackBar según el resultado de la eliminación
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isDeleted ? 'Factura eliminada correctamente' : 'Error al eliminar la factura',
                                                ),
                                                backgroundColor: isDeleted ? Colors.green : Colors.red, // Color de fondo del SnackBar
                                                behavior: SnackBarBehavior.floating,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );

                                            if (isDeleted) {
                                              setState(() {
                                                _facturasList.removeWhere((item) => item['id'] == invoice['id']);
                                                _filteredFacturas = _facturasList;
                                              });
                                            }
                                          }
                                        },

                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(color: Colors.red[300]!, width: 1),
                                        ),
                                      ),
                                    if (canAuthorize)
                                      TextButton.icon(
                                        icon: Icon(Icons.check, size: 14.0, color: Colors.green[800]),
                                        label: Text(
                                          'Autorizar',
                                          style: TextStyle(fontSize: 12.0, color: Colors.green[800]),
                                        ),
                                        onPressed: () {
                                           _authorizeInvoice();
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(color: Colors.green[300]!, width: 1),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 5,
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
