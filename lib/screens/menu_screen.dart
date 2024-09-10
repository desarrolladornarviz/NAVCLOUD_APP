import 'package:flutter/material.dart';
import 'allDocuments_screen.dart';
import 'createInvoice_screen.dart';
import 'createDocuments_screen.dart'; 
import 'home_screen.dart'; // Asegúrate de importar tu pantalla de inicio

class MenuScreen extends StatefulWidget {
  final int companyId;

  MenuScreen({required this.companyId});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // 0 for Home, 1 for Menu

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(), // Navegar a la pantalla de inicio
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(companyId: widget.companyId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: Text(''),
        automaticallyImplyLeading: false, // Elimina la flecha de retroceso
      bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green, // Color del indicador de selección
          labelColor: const Color.fromARGB(255, 0, 0, 0), // Color del texto de la pestaña seleccionada
          unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0), // Color del texto de la pestaña no seleccionada
          labelStyle: TextStyle(fontSize: 18.0), // Tamaño de fuente de la pestaña seleccionada
          unselectedLabelStyle: TextStyle(fontSize: 14.0), // Tamaño de fuente de la pestaña no seleccionada
          tabs: [
            Tab(text: 'Accesos Directos'),
            Tab(text: 'Todo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccesosDirectos(),
          _buildTodo(),
        ],
      ),
        bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: _onNavBarItemTapped,
  selectedItemColor: Colors.green,
  unselectedItemColor: Colors.grey,
  backgroundColor: Colors.white, // Color de fondo claro
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ],
),

    
    );
  }

  Widget _buildAccesosDirectos() {
    return GridView.count(
      padding: EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCard('Crear Factura', Icons.add_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateInvoiceScreen(companyId: widget.companyId),
            ),
          );
        }),
        _buildCard('Ver Facturas', Icons.file_copy_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllDocumentsScreen(companyId: widget.companyId),
            ),
          );
        }),
        _buildCard('Otros Documentos', Icons.description_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateDocumentsScreen(),
            ),
          );
        }),
        _buildCard('Clientes', Icons.people_outline, () {
          // Navegar a la pantalla de clientes
        }),
        _buildCard('Transacciones', Icons.monetization_on_outlined, () {
          // Navegar a la pantalla de transacciones
        }),
        _buildCard('Productos Y Servicios ', Icons.shopping_bag_outlined, () {
          // Navegar a la pantalla de productos
        }),
       
        _buildCard('Cotizaciones', Icons.assignment_outlined, () {
          // Navegar a la pantalla de cotizaciones
        }),
        _buildCard('Reportes de Pérdidas y Ganancias', Icons.pie_chart_outline, () {
          // Navegar a la pantalla de reportes
        }),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
  return Card(
    color: const Color.fromARGB(255, 255, 245, 245),
    elevation: 6.0, // Añadir sombra suave
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0), // Bordes más redondeados
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      splashColor: Colors.green.withOpacity(0.2), // Efecto al tocar
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.green), // Cambia el color del icono
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Mejor estilo de texto
          ),
        ],
      ),
    ),
  );
}


  Widget _buildTodo() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildMenuItem('Transacciones', Icons.monetization_on_outlined, () {
          // Navegar a la pantalla de transacciones
        }),
        _buildMenuItem('Reportes de Pérdidas y Ganancias', Icons.pie_chart_outline, () {
          // Navegar a la pantalla de reportes
        }),
        _buildMenuItem('Balance General', Icons.balance_outlined, () {
          // Navegar a la pantalla de balance general
        }),
        _buildMenuItem('Categorías', Icons.category_outlined, () {
          // Navegar a la pantalla de categorías
        }),
        ExpansionTile(
          title: Text('Entradas de Dinero'),
          leading: Icon(Icons.monetization_on_outlined),
          children: [
            _buildSubMenuItem('Clientes', Icons.person_outline, () {
              // Navegar a la pantalla de clientes
            }),
            _buildSubMenuItem('Cotizaciones', Icons.assignment_outlined, () {
               
            }),
            _buildSubMenuItem('Facturas', Icons.file_copy_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllDocumentsScreen(companyId: widget.companyId),
                  ),
                );
            }),
            _buildSubMenuItem('Pago de Facturas', Icons.payment_outlined, () {
              // Navegar a la pantalla de pago de facturas
            }),
            _buildSubMenuItem('Recibos', Icons.receipt_outlined, () {
              // Navegar a la pantalla de recibos
            }),
            _buildSubMenuItem('Productos', Icons.shopping_bag_outlined, () {
              // Navegar a la pantalla de productos
            }),
            _buildSubMenuItem('Servicios', Icons.build_outlined, () {
              // Navegar a la pantalla de servicios
            }),
          ],
        ),
        ExpansionTile(
          title: Text('Salida de Dinero'),
          leading: Icon(Icons.money_off_outlined),
          children: [
            _buildSubMenuItem('Proveedores', Icons.business_outlined, () {
              // Navegar a la pantalla de proveedores
            }),
            _buildSubMenuItem('Gastos', Icons.money_off_csred_outlined, () {
              // Navegar a la pantalla de gastos
            }),
          ],
        ),
        _buildMenuItem('Adjuntos', Icons.attach_file_outlined, () {
          // Navegar a la pantalla de adjuntos
        }),
        _buildMenuItem('Ayuda', Icons.help_outline, () {
          // Navegar a la pantalla de ayuda
        }),
        _buildMenuItem('Enviar Comentarios', Icons.comment_outlined, () {
          // Navegar a la pantalla de enviar comentarios
        }),
      ],
    );
  }

 Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0), // Separación entre los elementos
    child: ListTile(
      leading: Icon(icon, color: Colors.green), // Ícono con color temático
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500), // Estilo de texto mejorado
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: const Color.fromARGB(255, 235, 233, 233)), // Ícono de navegación
      onTap: onTap,
    ),
  );
}

Widget _buildSubMenuItem(String title, IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(left: 32.0), // Añadir un padding a la izquierda
    child: _buildMenuItem(title, icon, onTap), // Reutilizar el estilo de los menús
  );
}

}
