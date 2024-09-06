import 'package:flutter/material.dart';
import 'createInvoice_screen.dart';

class CreateDocumentsScreen extends StatelessWidget {
  final Map<String, dynamic>? company;

  CreateDocumentsScreen({this.company});

  @override
  Widget build(BuildContext context) {
    final companyId = company?['id'] ?? 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900], // Color de fondo más moderno
        title: Text(
          'Crear Documentos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDocumentOption(
              context,
              'Factura',
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
            _buildDocumentOption(
              context,
              'Nota de crédito',
              Icons.credit_card,
              Colors.orange,
              () {
                // Lógica para crear una nueva nota de crédito
              },
            ),
            _buildDocumentOption(
              context,
              'Nota de débito',
              Icons.credit_card,
              Colors.red,
              () {
                // Lógica para crear una nueva nota de débito
              },
            ),
            _buildDocumentOption(
              context,
              'Liquidación de compra',
              Icons.shopping_cart,
              Colors.green,
              () {
                // Lógica para crear una nueva liquidación de compra
              },
            ),
            _buildDocumentOption(
              context,
              'Retención',
              Icons.receipt,
              Colors.purple,
              () {
                // Lógica para crear una nueva retención
              },
            ),
            _buildDocumentOption(
              context,
              'Guía de Remisión',
              Icons.local_shipping,
              Colors.teal,
              () {
                // Lógica para crear una nueva guía de remisión
              },
            ),
            _buildDocumentOption(
              context,
              'Proforma',
              Icons.assignment,
              Colors.indigo,
              () {
                // Lógica para crear una nueva proforma
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Container(
        height: 70, // Altura específica para el Card
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Espaciado interno
          leading: Icon(icon, size: 40, color: color),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          onTap: onPressed,
        ),
      ),
    );
  }
}
