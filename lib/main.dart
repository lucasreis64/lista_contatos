import 'package:flutter/material.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  await load(); // Carrega as variáveis de ambiente do arquivo .env

  runApp(ContactApp());
}

class ContactApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContactScreen(),
    );
  }
}

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> contacts = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  File imageFile;

  @override
  void initState() {
    super.initState();
    initializeParse();
    fetchContacts();
  }

  void initializeParse() async {
    final parseAppId = env['PARSE_APP_ID'];
    final parseServerUrl = env['PARSE_SERVER_URL'];
    final parseClientKey = env['PARSE_CLIENT_KEY'];

    await Parse().initialize(
      parseAppId,
      parseServerUrl,
      clientKey: parseClientKey,
      debug: true,
    );
  }

  void fetchContacts() async {
    final queryBuilder = QueryBuilder<Contact>(Contact())
      ..orderByAscending('createdAt');
    final response = await queryBuilder.query();
    if (response.success && response.results != null) {
      setState(() {
        contacts = response.results;
      });
    }
  }

  Future<void> saveContact() async {
    final name = nameController.text;
    final phone = phoneController.text;

    if (name.isNotEmpty && phone.isNotEmpty) {
      final contact = Contact(name, phone, imageFile);

      final response = await contact.save();
      if (response.success) {
        fetchContacts();
        nameController.clear();
        phoneController.clear();
        imageFile = null;
      }
    }
  }

  // Implemente a função pickImage() para selecionar imagens

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda de Contatos'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            ElevatedButton(
              onPressed: () => pickImage(),
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
              onPressed: saveContact,
              child: Text('Salvar Contato'),
            ),
            SizedBox(height: 16),
            Text('Contatos Cadastrados:'),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.network(contacts[index].imageUrl),
                    title: Text(contacts[index].name),
                    subtitle: Text(contacts[index].phone),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    // Implemente a lógica de seleção de imagens
  }
}

class Contact extends ParseObject {
  Contact(String name, String phone, File image) : super('Contact') {
    set<String>('name', name);
    set<String>('phone', phone);
    if (image != null) {
      final parseFile = ParseFile(image);
      set<ParseFile>('image', parseFile);
    }
  }

  String get name => get<String>('name');
  String get phone => get<String>('phone');
  String get imageUrl => get<ParseFile>('image')?.url;
}
