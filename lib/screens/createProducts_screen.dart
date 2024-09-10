import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fact_nav/config.dart'; 

class CreateProductsScreen extends StatefulWidget {
  final int companyId;
  final Map<String, dynamic>? product;

  CreateProductsScreen({required this.companyId, this.product});

  @override
  _CreateProductsScreenState createState() => _CreateProductsScreenState();
}

class _CreateProductsScreenState extends State<CreateProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _precioUnitarioController = TextEditingController();
  final _subsidioController = TextEditingController();
  final _descuentoController = TextEditingController();
  final _ivaController = TextEditingController();
  final _irpnrController = TextEditingController();
  

  int _cantidad = 1;
  String _iva = '15%';
  double _descuento = 0.0;
  List<dynamic> _productos = [];
  int? _selectedProductId; 

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final product = widget.product!;
      _codigoController.text = product['codigo'] ?? '';
      _nombreController.text = product['nombre'] ?? '';
      _precioUnitarioController.text = product['precio_unitario']?.toString() ?? '';
      _subsidioController.text = product['subsidio']?.toString() ?? '';
      _descuentoController.text = product['descuento']?.toString() ?? '0';
      _iva = product['iva']?.toString() ?? '15%';
      _irpnrController.text = product['irpnr']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioUnitarioController.dispose();
    _subsidioController.dispose();
    _descuentoController.dispose();
    _ivaController.dispose();
    _irpnrController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchProducts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final String apiUrl = '${Config.baseUrl}api-productos/${widget.companyId}';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

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


 void _showProductosModal() async {
  try {
    final productos = await fetchProducts();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<dynamic> filteredProducts = List.from(productos);

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                            hintText: 'Buscar productos...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              filteredProducts = productos
                                  .where((producto) => producto['nombre']!.toLowerCase().contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => Divider(height: 1),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final producto = filteredProducts[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.0),
                              title: Text(producto['nombre'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Precio: ${producto['precio_unitario'] ?? ''}'),
                              onTap: () {
                                Navigator.pop(context, producto);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('Cerrar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((selectedProduct) {
      if (selectedProduct != null) {
        _codigoController.text = selectedProduct['codigo'] ?? '';
        _nombreController.text = selectedProduct['nombre'] ?? '';
        _precioUnitarioController.text = selectedProduct['precio_unitario']?.toString() ?? '';
        _subsidioController.text = selectedProduct['subsidio']?.toString() ?? '';
        _descuentoController.text = selectedProduct['descuento']?.toString() ?? '';
        _iva = selectedProduct['iva']?.toString() ?? '15%';
        _irpnrController.text = selectedProduct['irpnr']?.toString() ?? '';
        
        _selectedProductId = selectedProduct['id'];

        setState(() {});
      }
    });
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('No se pudieron cargar los productos. Inténtelo de nuevo más tarde.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}




  double _calculateTotal(double precioUnitario, double descuento, String iva) {
    double descuentoMonto = precioUnitario * (descuento / 100);
    double precioConDescuento = precioUnitario - descuentoMonto;
    double ivaMonto = precioConDescuento * (iva == '15%' ? 0.15 : 0.0);
    return precioConDescuento + ivaMonto;
  }

@override
  Widget build(BuildContext context) {
    
    double precioUnitario = double.tryParse(_precioUnitarioController.text) ?? 0.0;
    double descuento = _descuento;
    String iva = _iva;
    double total = _calculateTotal(precioUnitario, descuento, iva) * _cantidad;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Producto'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: _showProductosModal,
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey[900], // Color de fondo
                foregroundColor: Colors.white, // Color del texto
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Padding del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Bordes redondeados
                ),
                elevation: 5, // Sombra del botón
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store, size: 20, color: Colors.white), // Icono del botón
                  SizedBox(width: 8), // Espacio entre el icono y el texto
                  Text(
                    'Productos Guardados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Estilo del texto
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextFormField(
                        controller: _codigoController,
                        label: 'Código',
                          keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El Nombre  es obligatorio';
                          }
                          
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _nombreController,
                        label: 'Nombre',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El Nombre  es obligatorio';
                          }
                          
                          return null;
                        },
                      ),
                      _buildTextFormField(
                        controller: _precioUnitarioController,
                        label: 'Precio Unitario',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio unitario es obligatorio';
                          }
                          if (double.tryParse(value) == null) {
                            return 'El precio debe ser un número válido';
                          }
                          return null;
                        },
                      ),
                      /*_buildTextFormField(
                        controller: _subsidioController,
                        label: 'Subsidio',
                        keyboardType: TextInputType.number,
                      ),*/
                      _buildTextFormField(
                        controller: _descuentoController,
                        label: 'Descuento (0%)',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _descuento = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                      _buildDropdownFormField(
                        value: _iva,
                        label: 'IVA',
                        items: [
                          DropdownMenuItem(value: '15%', child: Text('15%')),
                          DropdownMenuItem(value: '0', child: Text('0%')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _iva = value!;
                          });
                        },
                      ),
                      /*_buildTextFormField(
                        controller: _irpnrController,
                        label: 'IRP/NR',
                        keyboardType: TextInputType.number,
                      ),*/
                      SizedBox(height: 20),
                      Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Control de cantidad
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                if (_cantidad > 1) {
                                  _cantidad--;
                                }
                              });
                            },
                          ),
                          Text(
                            'Cantidad: $_cantidad',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _cantidad++;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final producto = {
                              'id': _selectedProductId, // Asegúrate de incluir el id aquí
                              'codigo': _codigoController.text,
                              'nombre': _nombreController.text,
                              'precio_unitario': double.tryParse(_precioUnitarioController.text) ?? 0.0,
                              //'subsidio': double.tryParse(_subsidioController.text) ?? 0.0,
                              'descuento': _descuento,
                              'iva': _iva,
                              //'irpnr': double.tryParse(_irpnrController.text) ?? 0.0,
                              'cantidad': _cantidad,
                              'total': _calculateTotal(double.tryParse(_precioUnitarioController.text) ?? 0.0, _descuento, _iva) * _cantidad,
                            };

                            WidgetsBinding.instance!.addPostFrameCallback((_) {
                              Navigator.pop(context, producto);
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Color.fromARGB(255, 241, 242, 243),
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text('Guardar Producto'),
                      )

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
