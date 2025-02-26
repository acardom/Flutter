import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrestamoScreen extends StatelessWidget {
  final Map<String, dynamic> libro;
  PrestamoScreen({required this.libro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Realizar Préstamo"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              libro['image'] != null
                  ? Image.network(
                      libro['image'],
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error cargando imagen en préstamo: $error");
                        return Icon(Icons.book, size: 150);
                      },
                    )
                  : Icon(Icons.book, size: 150),
              SizedBox(height: 20),
              Text(
                "Título: ${libro['title'] ?? 'Título desconocido'}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Autor: ${libro['author'] ?? 'Autor desconocido'}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final borrowedBooksJson = prefs.getString('borrowedBooksWithDates') ?? '[]';
                  List<dynamic> borrowedBooks = json.decode(borrowedBooksJson);
                  final returnDate = DateTime.now().add(Duration(days: 7)).toString().substring(0, 10);
                  borrowedBooks.add({'title': libro['title'], 'returnDate': returnDate});
                  await prefs.setString('borrowedBooksWithDates', json.encode(borrowedBooks));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Préstamo confirmado")));
                  Navigator.pop(context);
                },
                child: Text("Confirmar Préstamo"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}