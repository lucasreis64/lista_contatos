import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(PersonApp());
}

class PersonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Pessoas',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController nameController = TextEditingController();
  DatabaseReference databaseReference;
  List<Person> people = [];
  File imageFile;

  @override
  void initState() {
    super.initState();
    databaseReference = FirebaseDatabase.instance.reference().child("people");
    fetchPeople();
  }

  void fetchPeople() {
    databaseReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      people.clear();
      if (values != null) {
        values.forEach((key, values) {
          people.add(Person.fromMap(values));
        });
      }
      setState(() {});
    });
  }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  void savePerson() async {
    final name = nameController.text;

    if (name.isNotEmpty && imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child(name);
      await ref.putFile(imageFile);

      final imageUrl = await ref.getDownloadURL();

      final person = Person(name, imageUrl);
      final id = databaseReference.push().key;

      databaseReference.child(id).set(person.toMap());
      nameController.clear();
      setState(() {
        imageFile = null;
      });
      fetchPeople();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Pessoas'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            ElevatedButton(
              onPressed: uploadImage,
              child: Text('Selecionar Imagem'),
            ),
            if (imageFile != null) ...[
              SizedBox(height: 16),
              Image.file(
                imageFile,
                width: 150,
                height: 150,
              ),
            ],
            ElevatedButton(
              onPressed: savePerson,
              child: Text('Salvar Pessoa'),
            ),
            SizedBox(height: 16),
            Text('Pessoas Cadastradas:'),
            Expanded(
              child: ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.network(people[index].imageUrl),
                    title: Text(people[index].name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Person {
  final String name;
  final String imageUrl;

  Person(this.name, this.imageUrl);

  factory Person.fromMap(Map<dynamic, dynamic> map) {
    return Person(map['name'], map['imageUrl']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
