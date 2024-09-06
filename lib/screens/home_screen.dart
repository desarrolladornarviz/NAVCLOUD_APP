import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'allDocuments_screen.dart';
import 'createInvoice_screen.dart';
import 'createDocuments_screen.dart'; // Importa la pantalla CreateDocumentsScreen

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? company;

  HomeScreen({this.company});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Elimina el token

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final companyName = company?['nombre_comercial'] ?? 'Unknown Company';
    final companyRUC = company?['ruc'] ?? 'Unknown RUC';
    final companyId = company?['id'] ?? 0; // Asume que el ID de la compañía está en el mapa
    final companyEmail = company?['email'] ?? 'Unknown Email'; // Asume que el email de la compañía está en el mapa

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800], // Color de fondo más moderno
        title: Text(
          'Inicio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 4,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                companyName, // Muestra el nombre comercial aquí
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                companyEmail, // Muestra el email aquí
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/images/profile.png'),
              ),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
              ),
            ),
            ListTile(
              leading: Icon(Icons.business, color: Colors.blueGrey[800]),
              title: Text('Seleccionar Compañía'),
              onTap: () {
                Navigator.pushNamed(context, '/selectCompany');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blueGrey[800]),
              title: Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'RUC: $companyRUC',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    'Nueva Factura',
                    Icons.file_copy,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvoiceScreen(companyId: companyId),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Nuevo Recibo',
                    Icons.receipt,
                    Colors.orange,
                    () {
                      // Lógica para nuevo recibo
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Nueva Proforma',
                    Icons.description,
                    Colors.green,
                    () {
                      // Lógica para nueva proforma
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Historial',
                    Icons.history,
                    Colors.teal,
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateDocumentsScreen(),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueGrey[800],
        elevation: 6,
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Center( // Centra el contenido vertical y horizontalmente
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
              crossAxisAlignment: CrossAxisAlignment.center, // Centra horizontalmente
              children: [
                Icon(icon, size: 50, color: color), // Aumenta el tamaño del icono
                SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
