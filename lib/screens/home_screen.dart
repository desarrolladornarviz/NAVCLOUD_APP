import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fact_nav/config.dart'; 
import 'allDocuments_screen.dart';
import 'createInvoice_screen.dart';
import 'createDocuments_screen.dart'; // Importa la pantalla CreateDocumentsScreen
import 'actividades_screen.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? company;

  HomeScreen({this.company});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _facturasTotal = 0.0; // Variable para almacenar el total de las facturas
  String _selectedFilter = 'Hoy'; // Filtro seleccionado

  // Obtén el companyId
  int get companyId => widget.company?['id'] ?? 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchFacturasTotal(); // Llama a la función para obtener el total de las facturas
  }

  Future<void> _fetchFacturasTotal() async {
    try {
      double total = await fetchFacturasTotal(_selectedFilter);
      setState(() {
        _facturasTotal = total;
      });
    } catch (e) {
      // Maneja el error de acuerdo a tus necesidades, por ejemplo, mostrando un mensaje al usuario
      print('Error fetching facturas total: $e');
    }
  }

 Future<double> fetchFacturasTotal(String filter) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
  final String apiUrl = '${Config.baseUrl}company/${widget.company?['id']}/documentos';
  try {
    final response = await http.get(
      
      Uri.parse(apiUrl),
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

          DateTime now = DateTime.now();
          DateTime startDate;
          DateTime endDate;

          switch (filter) {
            case 'Hoy':
              startDate = DateTime(now.year, now.month, now.day); // Inicio del día actual
              endDate = DateTime(now.year, now.month, now.day, 23, 59, 59); // Fin del día actual (23:59:59)
              break;
            case 'Este mes':
              startDate = DateTime(now.year, now.month, 1); // Inicio del mes actual
              endDate = DateTime(now.year, now.month + 1, 1); // Inicio del próximo mes
              break;
            case 'Anual':
              startDate = DateTime(now.year, 1, 1); // Inicio del año actual
              endDate = DateTime(now.year + 1, 1, 1); // Inicio del próximo año
              break;
            default:
              startDate = DateTime.now().subtract(Duration(days: 365)); // Default: último año
              endDate = DateTime.now(); // Fin del rango por defecto
              break;
          }

          // Filtrar las facturas según la fecha (solo comparando fechas, sin hora)
          facturas = facturas.where((factura) {
            DateTime fechaFactura = DateTime.parse(factura['fecha'].toString());
            DateTime onlyDateFactura = DateTime(fechaFactura.year, fechaFactura.month, fechaFactura.day);
            return onlyDateFactura.isAtSameMomentAs(startDate) || (onlyDateFactura.isAfter(startDate) && onlyDateFactura.isBefore(endDate));
          }).toList();

          // Ordenar las facturas por ID en orden descendente
          facturas.sort((a, b) {
            int idA = int.parse(a['id'].toString());
            int idB = int.parse(b['id'].toString());
            return idB.compareTo(idA); // Ordena de forma descendente
          });

          // Calcular la suma total de los montos
          double total = facturas.fold(0.0, (sum, factura) {
            return sum + (double.tryParse(factura['total'].toString()) ?? 0.0);
          });

          // Limitar el total a 2 decimales
          return double.parse(total.toStringAsFixed(2));
        } else {
          throw Exception('Estructura JSON inválida: falta la clave "facturas"');
        }
      } catch (e) {
        print('Error al analizar el JSON: $e');
        throw Exception('Error al analizar el JSON');
      }
    } else {
      print('Error al cargar documentos: ${response.statusCode}');
      throw Exception('Error al cargar documentos');
    }
  } catch (e) {
    print('Error al obtener facturas: $e');
    throw Exception('Error al cargar documentos');
  }
}


  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Elimina el token

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final companyName = company?['nombre_comercial'] ?? 'Unknown Company';
    final companyEmail = company?['email'] ?? 'Unknown Email';

    return Scaffold(
     appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          companyName,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () => _logout(context),
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título "Acciones Rápidas"
            Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: 16), // Espacio entre el título y el carrusel de íconos
            // Sección de íconos horizontales tipo historias de IG
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStoryIcon(
                      context,
                      'Factura',
                      Icons.file_copy_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateInvoiceScreen(companyId: companyId),
                          ),
                        );
                      },
                    ),
                    _buildStoryIcon(
                      context,
                      'Cliente',
                      Icons.person_outlined,
                      () {
                        // Navegar a la pantalla de recibo
                      },
                    ),
                    _buildStoryIcon(
                      context,
                      'Otros',
                      Icons.description_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateDocumentsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildStoryIcon(
                      context,
                      'Historial',
                      Icons.history_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllDocumentsScreen(companyId: companyId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16), // Espacio entre el carrusel y la tarjeta de facturas
            // Tarjeta para mostrar el total de las facturas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro por fechas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total de Facturas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedFilter,
                          items: <String>['Hoy', 'Este mes', 'Anual'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedFilter = newValue!;
                              _fetchFacturasTotal(); // Actualiza el total con el nuevo filtro
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16), // Espacio entre el filtro y el total de facturas
                    Container(
                      width: double.infinity, // Hace que el contenedor ocupe todo el ancho
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '\$$_facturasTotal',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16), // Espacio entre la tarjeta de facturas y la tarjeta de tareas
            // Tarjeta de tareas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tareas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Aquí puedes agregar contenido relacionado con las tareas
                    Text(
                      'Aquí puedes agregar contenido relacionado con las tareas...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
            ),
          SizedBox(height: 16), // Espacio opcional arriba de la tarjeta
            
            // Tarjeta de tareas
          Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  color: Colors.white,
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActividadesScreen(companyId: companyId,), // Navegar a ActividadesScreen
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity, // Asegura que la tarjeta ocupe todo el ancho disponible
      child: Row(
        children: [
          Icon(
            Icons.list, // Ícono que desees usar
            color: Colors.blue, // Color del ícono
          ),
          SizedBox(width: 8), // Espacio entre el ícono y el texto
          Flexible(
            child: Text(
              'Ver todas las actividades',
              style: TextStyle(
                fontSize: 18, // Tamaño de fuente ajustado para visibilidad
                color: Colors.blue, // Color de enlace típico
                // Eliminado el subrayado del texto
              ),
              overflow: TextOverflow.ellipsis, // Agrega puntos suspensivos si el texto es muy largo
            ),
          ),
        ],
      ),
    ),
  ),
)


         
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/home');
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuScreen(companyId: companyId),
                  ),
                );
                break;
            }
          });
        },
        selectedItemColor: Colors.green, // Color del ícono y texto seleccionados
        unselectedItemColor: Colors.black, // Color del ícono y texto no seleccionados
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menú',
          ),
        ],
      ),
    );
  }
Widget _buildStoryIcon(
  BuildContext context,
  String label,
  IconData icon,
  VoidCallback onPressed,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0), // Aumenta el espacio entre íconos
    child: Stack(
      clipBehavior: Clip.none, // Permite que el ícono verde sobresalga del contenedor
      children: [
        InkWell(
          onTap: onPressed,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco para los íconos
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // Color y opacidad de la sombra
                      spreadRadius: 2, // Expansión de la sombra
                      blurRadius: 4, // Difuminado de la sombra
                      offset: Offset(0, 3), // Desplazamiento de la sombra
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white, // Fondo blanco para el ícono
                  child: Icon(icon, size: 30, color: Colors.black), // Íconos en negro
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 23,
          right: 3,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green, // Color de fondo verde
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: Colors.white, // Color del ícono en blanco
            ),
          ),
        ),
      ],
    ),
  );
  }
}
