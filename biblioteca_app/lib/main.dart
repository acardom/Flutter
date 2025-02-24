import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [Home(), Catalogo(), Perfil()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Catálogo"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Biblioteca"),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/library_logo.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Botón blanco
                        foregroundColor: Colors.blueAccent, // Texto azul
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DevolucionScreen()),
                        );
                      },
                      child: Text("Devolver Libro"),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Botón blanco
                        foregroundColor: Colors.blueAccent, // Texto azul
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: () async {
                        await generateReport(context);
                      },
                      child: Text("Generar Informe de Préstamo"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generateReport(BuildContext context) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();
    final borrowedBooksJson = prefs.getString('borrowedBooksWithDates') ?? '[]';
    final returnedBooksJson = prefs.getString('returnedBooks') ?? '[]';
    final List<dynamic> borrowedBooks = json.decode(borrowedBooksJson);
    final List<dynamic> returnedBooks = json.decode(returnedBooksJson);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/library_logo.jpg')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Informe de Préstamos", style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Image(logoImage, width: 100, height: 100),
            pw.SizedBox(height: 20),
            pw.Text("Usuario: Juan Pérez"),
            pw.SizedBox(height: 10),
            pw.Text("Libros en préstamo:"),
            pw.Text(
              borrowedBooks.isEmpty
                  ? "Ningún libro en préstamo"
                  : borrowedBooks.map((book) => book['title']).join(", "),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Libros devueltos:"),
            returnedBooks.isEmpty
                ? pw.Text("Ningún libro devuelto")
                : pw.Column(
                    children: returnedBooks.map((book) => pw.Text(
                        "${book['title']} (${book['returnedDate']})")).toList(),
                  ),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF generado y abierto")),
    );
  }
}

class Catalogo extends StatefulWidget {
  @override
  _CatalogoState createState() => _CatalogoState();
}

class _CatalogoState extends State<Catalogo> {
  List<dynamic> books = [];
  List<String> borrowedBooks = [];
  TextEditingController _searchController = TextEditingController();

  Future<void> fetchBooks({String query = "programming"}) async {
    try {
      final response = await http.get(Uri.parse(
          'https://openlibrary.org/search.json?q=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          books = data['docs'] ?? [];
        });
      } else {
        print("Error en la respuesta de la API: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al obtener los libros: $e");
    }
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
                if (query.isNotEmpty) {
                  fetchBooks(query: query);
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              fetchBooks(query: value.trim());
            }
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
                    title: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Autor: $author", style: TextStyle(color: Colors.grey[700])),
                          Text("Materia: $subject", style: TextStyle(color: Colors.grey[700])),
                          Text("Estado: $status",
                              style: TextStyle(
                                  color: isBorrowed ? Colors.red : Colors.green)),
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
                                  }))).then((_) => _loadBorrowedBooks());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Este libro ya está en préstamo")),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class Perfil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil"),
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
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "Juan Pérez",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Usuario de la biblioteca",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  borrowedBooks.add({
                    'title': libro['title'],
                    'returnDate': returnDate,
                  });
                  await prefs.setString('borrowedBooksWithDates', json.encode(borrowedBooks));
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Préstamo confirmado")));
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

                            final bookToReturn = borrowedBooks.firstWhere((book) => book['title'] == selectedBook);
                            borrowedBooks.removeWhere((book) => book['title'] == selectedBook);
                            returnedBooks.add({
                              'title': bookToReturn['title'],
                              'returnedDate': DateTime.now().toString().substring(0, 10),
                            });

                            await prefs.setString('borrowedBooksWithDates', json.encode(borrowedBooks));
                            await prefs.setString('returnedBooks', json.encode(returnedBooks));
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Devolución confirmada")));
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