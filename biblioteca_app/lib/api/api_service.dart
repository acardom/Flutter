import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  Future<List<dynamic>> fetchBooks({String query = "programming"}) async {
    try {
      final response = await http.get(Uri.parse('https://openlibrary.org/search.json?q=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['docs'] ?? [];
      } else {
        print("Error en la respuesta de la API: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error al obtener los libros: $e");
      return [];
    }
  }
}