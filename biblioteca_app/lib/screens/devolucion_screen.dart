import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DevolucionScreen extends StatefulWidget {
  @override
  _DevolucionScreenState createState() => _DevolucionScreenState();
}

class _DevolucionScreenState extends State<DevolucionScreen> {
  String? selectedBook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Devolución de Libros"),
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
          child: FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final prefs = snapshot.data!;
              final borrowedBooksJson = prefs.getString('borrowedBooksWithDates') ?? '[]';
              final List<dynamic> borrowedBooks = json.decode(borrowedBooksJson);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Selecciona un libro",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: selectedBook,
                      items: borrowedBooks.map<DropdownMenuItem<String>>((book) {
                        return DropdownMenuItem<String>(
                          value: book['title'] as String,
                          child: Text("${book['title']} (Dev. estimada: ${book['returnDate']})"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBook = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    onPressed: selectedBook == null
                        ? null
                        : () async {
                            final prefs = await SharedPreferences.getInstance();
                            final borrowedBooksJson = prefs.getString('borrowedBooksWithDates') ?? '[]';
                            List<dynamic> borrowedBooks = json.decode(borrowedBooksJson);
                            final returnedBooksJson = prefs.getString('returnedBooks') ?? '[]';
                            List<dynamic> returnedBooks = json.decode(returnedBooksJson);

                            final bookToReturn =
                                borrowedBooks.firstWhere((book) => book['title'] == selectedBook);
                            borrowedBooks.removeWhere((book) => book['title'] == selectedBook);
                            returnedBooks.add({
                              'title': bookToReturn['title'],
                              'returnedDate': DateTime.now().toString().substring(0, 10),
                            });

                            await prefs.setString('borrowedBooksWithDates', json.encode(borrowedBooks));
                            await prefs.setString('returnedBooks', json.encode(returnedBooks));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text("Devolución confirmada")));
                            Navigator.pop(context);
                          },
                    child: Text("Confirmar Devolución"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}