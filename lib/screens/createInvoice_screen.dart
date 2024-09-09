import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'clientes_screen.dart';
import 'createProducts_screen.dart';
import 'allDocuments_screen.dart';


class CreateInvoiceScreen extends StatefulWidget {
  final int companyId;
  final Map<String, dynamic>? producto;

  CreateInvoiceScreen({required this.companyId, this.producto });

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _invoiceTileKey = GlobalKey();
  final GlobalKey _clientDetailsTileKey = GlobalKey();
  final GlobalKey _productsTileKey = GlobalKey();
  final GlobalKey _paymentTileKey = GlobalKey();
  final GlobalKey _infoTileKey = GlobalKey();
  final _establecimientoController = TextEditingController();
  final _puntoEmisionController = TextEditingController();
  final _secuencialController = TextEditingController();
  final _fechaController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _totalController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _productosController = TextEditingController();
  final _formaPagoController = TextEditingController();
  final _informacionAdicionalController = TextEditingController();
  final _correoController = TextEditingController();
  final _identificacionController = TextEditingController();

  bool _isInvoiceExpanded = true;
  bool _isClientDetailsExpanded = false;
  bool _isProductsExpanded = false;
  bool _isPaymentMethodExpanded = false;
  bool _isAdditionalInfoExpanded = false;

  List<Map<String, dynamic>> _puntosDeEmision = [];
  String? _puntoEmisionSeleccionado;
  List<Map<String, dynamic>> _establecimientos = [];
  String? _establecimientoSeleccionado;
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _metodosDePago = [];
  Map<String, dynamic>? _metodoDePagoSeleccionado;

  
  @override
  void initState() {
    super.initState();
    _fetchNumeroFacturaData();
    _fetchMetodosDePago();
  }

  @override
    void dispose() {
    _establecimientoController.dispose();
    _puntoEmisionController.dispose();
    _secuencialController.dispose();
    _fechaController.dispose();
    _subtotalController.dispose();
    _totalController.dispose();
    _razonSocialController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _productosController.dispose();
    _formaPagoController.dispose();
    _informacionAdicionalController.dispose();
    _correoController.dispose();
    _identificacionController.dispose();
    super.dispose();
  }


Future<void> _fetchMetodosDePago() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
  final url = 'http://192.168.100.34:8000/api/v1/metodos';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Decoded data: $data'); // Mostrar datos decodificados

      final List<Map<String, dynamic>> metodosDePago = List<Map<String, dynamic>>.from(data);

      setState(() {
        _metodosDePago = metodosDePago;
        _metodoDePagoSeleccionado = _metodosDePago.isNotEmpty ? _metodosDePago[0] : null;
      });
    } else {
      print('Error en la solicitud: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los métodos de pago')),
      );
    }
  } catch (e) {
    print('Excepción capturada: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al obtener los métodos de pago')),
    );
  }
}

Future<void> _fetchNumeroFacturaData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final url = 'http://192.168.100.34:8000/api/v1/numero-factura/${widget.companyId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> puntosDeEmision = List<Map<String, dynamic>>.from(data['puntosDeEmision']);
      final List<Map<String, dynamic>> establecimientos = List<Map<String, dynamic>>.from(data['establecimientos']);

      setState(() {
        _establecimientoController.text = data['establecimientos'][0]['codigo_establecimiento'] ?? '';
        _puntosDeEmision = puntosDeEmision;
        _establecimientos = establecimientos;
        _puntoEmisionSeleccionado = _puntosDeEmision.isNotEmpty ? _puntosDeEmision[0]['codigo'] as String : null;
        _establecimientoSeleccionado = _establecimientos.isNotEmpty ? _establecimientos[0]['codigo_establecimiento'] as String : null;

        if (_establecimientoSeleccionado != null) {
          final establecimientosSeleccionado = _establecimientos.firstWhere(
            (punto) => punto['codigo'] == _establecimientoSeleccionado,
            orElse: () => {'secuencial_factura': 0}, // Valor predeterminado
          );
          final int secuencialFactura = establecimientosSeleccionado['secuencial_factura'] ?? 0;
          _puntoEmisionController.text = (secuencialFactura + 1).toString().padLeft(10, '0');
        }

        if (_puntoEmisionSeleccionado != null) {
          final puntoSeleccionado = _puntosDeEmision.firstWhere(
            (punto) => punto['codigo'] == _puntoEmisionSeleccionado,
            orElse: () => {'secuencial_factura': 0}, // Valor predeterminado
          );
          final int secuencialFactura = puntoSeleccionado['secuencial_factura'] ?? 0;
          _secuencialController.text = (secuencialFactura + 1).toString().padLeft(10, '0');
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los datos de la factura')),
      );
    }
  }

Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != currentDate) {
      setState(() {
        _fechaController.text = '${selectedDate.toLocal()}'.split(' ')[0];
      });
    }
  }

Future<void> _selectCliente() async {
  final selectedCliente = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ClientesScreen(companyId: widget.companyId.toString()),
    ),
  );

  if (selectedCliente != null) {
    print('Selected Cliente Data: $selectedCliente'); // Imprime toda la información del cliente

    setState(() {
      _razonSocialController.text = selectedCliente['razon_social'] ?? '';
      _direccionController.text = selectedCliente['direccion'] ?? '';  
      _telefonoController.text = selectedCliente['telefono'] ?? '';
      _correoController.text = selectedCliente['email'] ?? '';
      _identificacionController.text = selectedCliente['identificacion'] ?? '';
    });
  }
}

Future<void> _selectProducto() async {
    final productoSeleccionado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductsScreen(companyId: widget.companyId),
      ),
    );

    if (productoSeleccionado != null) {
      setState(() {
        _productos.add(productoSeleccionado); // Agregar el producto seleccionado
      });
    }
  }

String _productosToString() {
    return _productos.map((producto) {
      return '${producto['nombre']} - ${producto['precio']}';
    }).join('\n');
  }

void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      _productos.add(producto);
    });
  }

void _removeProducto(Map<String, dynamic> producto) {
  setState(() {
    _productos.remove(producto);
  });
}

double _calculateTotal() {
  double total = 0.0;
  for (var producto in _productos) {
    total += producto['total'];
  }
  return total;
}

Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Evita que el usuario cierre el diálogo al tocar fuera de él
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text('¿Estás seguro de que quieres crear esta factura?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin hacer nada
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _createInvoice(); // Llama a la función para crear la factura
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _createInvoice() async {
  if (_formKey.currentState!.validate()) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final numeroDocumento = '${_establecimientoController.text}-${_puntoEmisionSeleccionado}-${_secuencialController.text}';

      if (_razonSocialController.text.isEmpty ||
          _identificacionController.text.isEmpty ||
          _correoController.text.isEmpty ||
          _direccionController.text.isEmpty ||
          _telefonoController.text.isEmpty ||
          _metodoDePagoSeleccionado == null ||
          _productos.isEmpty) {
        throw Exception('Todos los campos del cliente y los detalles de la factura deben ser completados.');
      }

      final body = json.encode({
      'factura': {
        'cliente_nombre': _razonSocialController.text,
        'cliente_identificacion': _identificacionController.text,
        'cliente_email': _correoController.text,
        'cliente_direccion': _direccionController.text,
        'cliente_telefono': _telefonoController.text,
        'numero_documento': numeroDocumento,
        'fecha': _fechaController.text,
        'metodo_pago_id': _metodoDePagoSeleccionado?['id'] ?? '',
        'observaciones': _informacionAdicionalController.text.isNotEmpty ? _informacionAdicionalController.text : null,
        'cuenta_sri_id': widget.companyId, // Asegúrate de que widget.companyId sea el tipo correcto
      },
      'factura_detalle': _productos.map((producto) => {
        'cantidad': double.tryParse(producto['cantidad'].toString()) ?? 0.0,
        'producto_id': producto['id'].toString(),
        'producto_nombre': producto['nombre'],
        'precio_unitario': double.tryParse(producto['precio_unitario'].toString()) ?? 0.0,
        'iva': producto['iva'] == '15%' ? 15.0 : 0.0,  // Verifica la asignación correcta de IVA
        'ice': double.tryParse(producto['ice']?.toString() ?? '0') ?? 0.0,
        'descuento_porcentaje': double.tryParse(producto['descuento']?.toString() ?? '0') ?? 0.0,
      }).toList(),
    });


      print('Request URL: http://192.168.100.34:8000/api/v1/factura-app/create');
      print('Request Headers:');
      print({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      print('Request Body: $body');

      final response = await http.post(
        Uri.parse('http://192.168.100.34:8000/api/v1/factura-app/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Factura creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirigir a la pantalla allDocuments
        // Redirigir a la pantalla allDocuments con parámetros
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AllDocumentsScreen(companyId: widget.companyId),
            ),
          );
        });
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la factura: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800], // Color de fondo del AppBar
        title: Text(
          'Crear Factura',
          style: TextStyle(
            color: Colors.white, // Color del texto
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Color de los íconos (incluidas las flechas)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            children: [
              _buildInvoiceSection(),
              SizedBox(height: 16.0),
              _buildClientDetailsSection(),
              SizedBox(height: 16.0),
              _buildProductsSection(),
              SizedBox(height: 16.0),
              _buildPaymentMethodSection(),
              SizedBox(height: 16.0),
              _buildAdditionalInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() {
  return Card(
    key: _invoiceTileKey,
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Row(
            children: [
              Icon(Icons.receipt, color: Colors.blueGrey[800]),
              SizedBox(width: 8),
              Text('Factura', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: Icon(
            _isInvoiceExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.blueGrey[800],
          ),
          onTap: () {
            setState(() {
              _isInvoiceExpanded = !_isInvoiceExpanded;
              if (_isInvoiceExpanded) {
                _isClientDetailsExpanded = false;
                _isProductsExpanded = false;
                _isPaymentMethodExpanded = false;
                _isAdditionalInfoExpanded = false;
              }
            });
            if (_isInvoiceExpanded) {
              _scrollToNextSection();
            }
          },
        ),
        AnimatedCrossFade(
          firstChild: SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      SizedBox(width: 5),
                      Flexible(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _establecimientoSeleccionado,
                          items: _establecimientos.map((punto) {
                            return DropdownMenuItem<String>(
                              value: punto['codigo_establecimiento'] as String,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${punto['codigo_establecimiento']} - ${punto['nombre']}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _puntoEmisionSeleccionado = value;

                              final puntoSeleccionado = _puntosDeEmision.firstWhere(
                                (punto) => punto['codigo'] == _puntoEmisionSeleccionado,
                                orElse: () => {'secuencial_factura': 0},
                              );
                              final int secuencialFactura = puntoSeleccionado['secuencial_factura'] ?? 0;
                              _secuencialController.text = (secuencialFactura + 1).toString().padLeft(10, '0');
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Punto de Emisión',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _puntoEmisionSeleccionado,
                          items: _puntosDeEmision.map((punto) {
                            return DropdownMenuItem<String>(
                              value: punto['codigo'] as String,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${punto['codigo']} - ${punto['nombre']}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _puntoEmisionSeleccionado = value;

                              final puntoSeleccionado = _puntosDeEmision.firstWhere(
                                (punto) => punto['codigo'] == _puntoEmisionSeleccionado,
                                orElse: () => {'secuencial_factura': 0},
                              );
                              final int secuencialFactura = puntoSeleccionado['secuencial_factura'] ?? 0;
                              _secuencialController.text = (secuencialFactura + 1).toString().padLeft(10, '0');
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Punto de Emisión',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _secuencialController,
                          decoration: InputDecoration(
                            labelText: 'Secuencial',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          readOnly: true,
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // Espaciado debajo del campo de fecha
                  child: TextFormField(
                    controller: _fechaController,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la fecha';
                      }
                      return null;
                    },
                  ),
                ),
                // Puedes agregar más widgets aquí si es necesario
              ],
            ),
          ),
          crossFadeState: _isInvoiceExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: Duration(milliseconds: 300),
        ),
        _isInvoiceExpanded
            ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isInvoiceExpanded = false;
                        _isClientDetailsExpanded = true;
                      });
                      _scrollToNextSection();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey[800], // Color del texto
                    ),
                    child: Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
      ],
    ),
  );
}

  Widget _buildClientDetailsSection() {
    return Card(
      key: _clientDetailsTileKey,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.blueGrey[800]),
                SizedBox(width: 8),
                Text('Detalles del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(
              _isClientDetailsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blueGrey[800],
            ),
            onTap: () {
              setState(() {
                _isClientDetailsExpanded = !_isClientDetailsExpanded;
                if (_isClientDetailsExpanded) {
                  _isProductsExpanded = false;
                  _isPaymentMethodExpanded = false;
                  _isAdditionalInfoExpanded = false;
                }
              });
              if (_isClientDetailsExpanded) {
                _scrollToNextSection();
              }
            },
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild:  Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.count(
                                crossAxisCount: 2, // Dos columnas
                                crossAxisSpacing: 8.0, // Espacio horizontal entre columnas
                                mainAxisSpacing: 8.0, // Espacio vertical entre filas
                                shrinkWrap: true, // Ajustar el tamaño del GridView
                                childAspectRatio: 3 / 1.5, // Relación de aspecto para controlar la altura de los campos
                                physics: NeverScrollableScrollPhysics(), // Deshabilitar el scroll
                                children: [
                                  TextFormField(
                                    controller: _identificacionController,
                                    decoration: InputDecoration(
                                      labelText: 'Identificación',
                                      alignLabelWithHint: true, // Alinea la etiqueta con la parte superior
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa la Identificación';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _razonSocialController,
                                    maxLines: 5, // Aumenta la altura del campo
                                    decoration: InputDecoration(
                                      labelText: 'Razón Social',
                                      alignLabelWithHint: true, // Alinea la etiqueta con la parte superior
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa la razón social';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _correoController,
                                    decoration: InputDecoration(
                                      labelText: 'Correo',
                                      alignLabelWithHint: true, // Alinea la etiqueta con la parte superior
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa el Correo';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _direccionController,
                                    maxLines: 5, // Aumenta la altura del campo
                                    decoration: InputDecoration(
                                      labelText: 'Dirección',
                                      alignLabelWithHint: true, // Alinea la etiqueta con la parte superior
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa la dirección';
                                      }
                                      return null;
                                    },
                                  ),
                                    TextFormField(
                                    controller: _telefonoController,
                                    maxLines: 5, // Aumenta la altura del campo
                                    decoration: InputDecoration(
                                      labelText: 'Telefono',
                                      alignLabelWithHint: true, // Alinea la etiqueta con la parte superior
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa el Teléfono';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                             
                              SizedBox(height: 16.0),
                                TextButton(
                                  onPressed: _selectCliente,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Ajusta el padding para más espacio
                                    backgroundColor: const Color.fromARGB(255, 38, 74, 233), // Fondo blanco para que el texto resalte
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0), // Bordes redondeados
                                      side: BorderSide(color: Colors.blueAccent, width: 1.5), // Borde azul
                                    ),
                                    elevation: 2, // Añade elevación para un efecto de sombra
                                  ),
                                  child: Text(
                                    'Ver Clientes guardados',
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 253, 254, 255), // Color del texto
                                      fontSize: 13.0, // Tamaño de fuente
                                      fontWeight: FontWeight.w600, // Peso de fuente más grueso
                                      decoration: TextDecoration.none, // Sin subrayado
                                    ),
                                  ),
                                ),

                            ],
                          ),
                        ),
            crossFadeState: _isClientDetailsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
          _isClientDetailsExpanded
              ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isClientDetailsExpanded = false;
                        _isProductsExpanded = true;
                      });
                      _scrollToNextSection();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey[800], // Color del texto
                    ),
                    child: Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      key: _productsTileKey,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blueGrey[800]),
                SizedBox(width: 8),
                Text('Productos', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(
              _isProductsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blueGrey[800],
            ),
            onTap: () {
              setState(() {
                _isProductsExpanded = !_isProductsExpanded;
                if (_isProductsExpanded) {
                  _isPaymentMethodExpanded = false;
                  _isAdditionalInfoExpanded = false;
                }
              });
              if (_isProductsExpanded) {
                _scrollToNextSection();
              }
            },
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild:  Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                ..._productos.map((producto) => ListTile(
                                  title: Text('${producto['nombre']}'),
                                  subtitle: Text(
                                    'Cantidad: ${producto['cantidad']} - Precio: \$${producto['precio_unitario'].toStringAsFixed(2)} - Total: \$${producto['total'].toStringAsFixed(2)}',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _removeProducto(producto);
                                    },
                                  ),
                                )).toList(),
                                SizedBox(height: 20),
                                // Total del valor de los productos
                                Text(
                                  'Valor total: \$${_calculateTotal().toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _selectProducto,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey[900],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Agregar Producto'),
                                ),
                              ],
                            ),
                          ),
            crossFadeState: _isProductsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
          _isProductsExpanded
         ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isProductsExpanded = false;
                        _isPaymentMethodExpanded = true;
                      });
                      _scrollToNextSection();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey[800], // Color del texto
                    ),
                    child: Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      key: _paymentTileKey,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Row(
              children: [
                Icon(Icons.payment, color: Colors.blueGrey[800]),
                SizedBox(width: 8),
                Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(
              _isPaymentMethodExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blueGrey[800],
            ),
            onTap: () {
              setState(() {
                _isPaymentMethodExpanded = !_isPaymentMethodExpanded;
                if (_isPaymentMethodExpanded) {
                  _isAdditionalInfoExpanded = false;
                }
              });
              if (_isPaymentMethodExpanded) {
                _scrollToNextSection();
              }
            },
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child:DropdownButtonFormField<Map<String, dynamic>>(
              value: _metodoDePagoSeleccionado,
              items: _metodosDePago.map((metodo) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: metodo,
                  child: Text(
                    metodo['nombre'],
                    style: TextStyle(
                      fontSize: 14.0,  // Tamaño de la fuente
                      color: Colors.black,  // Color negro para las opciones
                      fontWeight: FontWeight.w500,  // Grosor de las letras
                    ),
                  ),
                );
              }).toList(),
              onChanged: (selectedMethod) {
                setState(() {
                  _metodoDePagoSeleccionado = selectedMethod;
                });
              },
              decoration: InputDecoration(
                labelText: 'Seleccionar Método de Pago',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              style: TextStyle(
                fontSize: 14.0,  // Tamaño de la fuente del ítem seleccionado
                color: Colors.black,  // Color negro para el ítem seleccionado
              ),
              dropdownColor: Colors.white,  // Color del fondo del menú desplegable
              isExpanded: true,  // Hace que el menú ocupe todo el ancho disponible
              isDense: true,  // Reduce el tamaño del campo para compactarlo
              icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey[800]),  // Personaliza el icono del desplegable
              iconSize: 28.0,  // Tamaño del icono
              menuMaxHeight: 300.0,  // Altura máxima del menú desplegable
              borderRadius: BorderRadius.circular(12.0),  // Bordes redondeados para las opciones
            )



            ),
            crossFadeState: _isPaymentMethodExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
          _isPaymentMethodExpanded
              ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isPaymentMethodExpanded = false;
                        _isAdditionalInfoExpanded = true;
                      });
                      _scrollToNextSection();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey[800], // Color del texto
                    ),
                    child: Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      key: _infoTileKey,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Row(
              children: [
                Icon(Icons.info, color: Colors.blueGrey[800]),
                SizedBox(width: 8),
                Text('Información Adicional', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(
              _isAdditionalInfoExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blueGrey[800],
            ),
            onTap: () {
              setState(() {
                _isAdditionalInfoExpanded = !_isAdditionalInfoExpanded;
              });
              if (_isAdditionalInfoExpanded) {
                _scrollToNextSection();
              }
            },
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notas Adicionales',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            crossFadeState: _isAdditionalInfoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
          _isAdditionalInfoExpanded
              ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  _showConfirmationDialog();  // Ejecuta la función al presionar el botón
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Guardar Factura',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,  // Color del texto en blanco
                  ),
                ),
              ),
            )


              : SizedBox.shrink(),
        ],
      ),
    );
  }

  void _scrollToNextSection() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _getSectionOffset(),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  double _getSectionOffset() {
    final RenderBox renderBox = _clientDetailsTileKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox?.localToGlobal(Offset.zero)?.dy ?? 0;
  }
}