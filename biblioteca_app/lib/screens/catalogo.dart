import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'prestamo_screen.dart';

class Catalogo extends StatefulWidget {
  @override
  _CatalogoState createState() => _CatalogoState();
}

class _CatalogoState extends State<Catalogo> {
  List<dynamic> books = [];
  List<String> borrowedBooks = [];
  TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  Future<void> fetchBooks({String query = "programming"}) async {
    final fetchedBooks = await _apiService.fetchBooks(query: query);
    setState(() {
      books = fetchedBooks;
    });
    await _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final borrowedBooksJson = prefs.getString('borrowedBooksWithDates') ?? '[]';
    final List<dynamic> borrowedBooksData = json.decode(borrowedBooksJson);
    setState(() {
      borrowedBooks = borrowedBooksData.map((book) => book['title'] as String).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Buscar libros...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) fetchBooks(query: query);
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) fetchBooks(query: value.trim());
          },
        ),
      ),
      body: books.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final title = book['title'] ?? "Título desconocido";
                final author = book['author_name']?.join(", ") ?? "Autor desconocido";
                final subject = book['subject']?.join(", ") ?? "Sin materia";
                final coverId = book['cover_i'];
                final imageUrl = coverId != null
                    ? "https://covers.openlibrary.org/b/id/$coverId-M.jpg"
                    : "https://via.placeholder.com/150";
                final isBorrowed = borrowedBooks.contains(title);
                final status = isBorrowed ? "En préstamo" : "Disponible";

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Autor: $author", style: TextStyle(color: Colors.grey[700])),
                          Text("Materia: $subject", style: TextStyle(color: Colors.grey[700])),
                          Text("Estado: $status",
                              style: TextStyle(color: isBorrowed ? Colors.red : Colors.green)),
                        ],
                      ),
                    ),
                    leading: Image.network(
                      imageUrl,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error cargando imagen: $error");
                        return Icon(Icons.book, size: 50);
                      },
                    ),
                    onTap: () {
                      if (!isBorrowed) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrestamoScreen(libro: {
                                    "title": title,
                                    "author": author,
                                    "image": imageUrl,
                                  })),
                        ).then((_) => _loadBorrowedBooks());
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("Este libro ya está en préstamo")));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}