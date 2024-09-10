import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:fact_nav/config.dart'; 
class SelectCompanyScreen extends StatefulWidget {
  @override
  _SelectCompanyScreenState createState() => _SelectCompanyScreenState();
}

class _SelectCompanyScreenState extends State<SelectCompanyScreen> {
  List<Map<String, dynamic>> companies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final String apiUrl = '${Config.baseUrl}user-companies';
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        print('Response data: $responseData');

        if (responseData['companies'] is List) {
          setState(() {
            companies = List<Map<String, dynamic>>.from(
              responseData['companies']
            );
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load companies')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seleccionar Empresa',
          style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
        backgroundColor: Colors.blueGrey[900]
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final logoUrl = company['logo'] != null ? company['logo']['url'] : '';
                  final razonSocial = company['nombre_comercial'] ?? 'Unknown';
                  final ruc = company['ruc'] ?? 'Unknown';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(company: company),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                                  child: Image.network(
                                    logoUrl,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  height: 120,
                                  child: Center(
                                    child: Icon(
                                      Icons.business,
                                      size: 60,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ruc,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  razonSocial,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
