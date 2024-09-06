import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClientesScreen extends StatefulWidget {
  final String companyId;

  ClientesScreen({required this.companyId});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<dynamic>> _clientes;

  @override
  void initState() {
    super.initState();
    _clientes = fetchClientes();
  }

  Future<List<dynamic>> fetchClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.get(
        Uri.parse('http://192.168.100.34:8000/api/v1/api-clientes/${widget.companyId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('clientes')) {
          final clientes = data['clientes'];
          if (clientes is List<dynamic>) {
            return clientes;
          } else {
            throw Exception('Clientes data is not a list');
          }
        } else {
          throw Exception('Invalid JSON structure');
        }
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (e) {
      throw Exception('Failed to fetch clients');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _clientes = fetchClientes(); // Actualizar la lista al presionar el ícono
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Añadir padding alrededor del contenido
        child: FutureBuilder<List<dynamic>>(
          future: _clientes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No hay clientes disponibles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final cliente = snapshot.data![index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      leading: Icon(Icons.person, size: 40.0, color: Colors.blueGrey), // Ícono de persona
                      title: Text(
                        cliente['razon_social'] ?? 'Nombre no disponible',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(cliente['email'] ?? 'Email no disponible'),
                      onTap: () {
                        Navigator.pop(context, cliente); // Regresar el cliente seleccionado a la pantalla anterior
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
