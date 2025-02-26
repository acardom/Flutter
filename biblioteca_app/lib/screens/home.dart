import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'devolucion_screen.dart';

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
            Image.asset('assets/library_logo.jpg', width: 150, height: 150, fit: BoxFit.contain),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DevolucionScreen()));
                      },
                      child: Text("Devolver Libro"),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
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
              borrowedBooks.isEmpty ? "Ningún libro en préstamo" : borrowedBooks.map((book) => book['title']).join(", "),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Libros devueltos:"),
            returnedBooks.isEmpty
                ? pw.Text("Ningún libro devuelto")
                : pw.Column(
                    children: returnedBooks.map((book) => pw.Text("${book['title']} (${book['returnedDate']})")).toList(),
                  ),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generado y abierto")));
  }
}