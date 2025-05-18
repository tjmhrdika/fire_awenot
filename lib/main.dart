import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/book.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Book CRUD',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return BookCrudPage();
        } else {
          return AuthPage();
        }
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void _submit() async {
    try {
      if (isLogin) {
        await AuthService.signIn(emailController.text.trim(), passwordController.text.trim());
      } else {
        await AuthService.register(emailController.text.trim(), passwordController.text.trim());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isLogin ? 'Login' : 'Register')),
            TextButton(onPressed: _toggleMode, child: Text(isLogin ? 'Create Account' : 'Already have an account?')),
          ],
        ),
      ),
    );
  }
}

class BookCrudPage extends StatelessWidget {
  void _showBookForm({BookWithId? bookWithId}) {
    final titleController = TextEditingController(text: bookWithId?.book.title);
    final authorController = TextEditingController(text: bookWithId?.book.author);

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: Text(bookWithId == null ? 'Add Book' : 'Update Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: authorController, decoration: InputDecoration(labelText: 'Author')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final book = Book(title: titleController.text, author: authorController.text);
                if (bookWithId == null) {
                  FirestoreService.addBook(book);
                  NotificationService.showNotification(title: 'Book Added', body: book.title);
                } else {
                  FirestoreService.updateBook(bookWithId.id, book);
                  NotificationService.showNotification(title: 'Book Updated', body: book.title);
                }
                Navigator.pop(context);
              },
              child: Text(bookWithId == null ? 'Add' : 'Update'),
            )
          ],
        );
      },
    );
  }

  void _deleteBook(String id) {
    FirestoreService.deleteBook(id);
    NotificationService.showNotification(title: 'Book Deleted', body: id);
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: Text('My Books'),
          actions: [IconButton(onPressed: AuthService.signOut, icon: Icon(Icons.logout))],
        ),
        body: StreamBuilder<List<BookWithId>>(
          stream: FirestoreService.getBooks(uid!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final books = snapshot.data ?? [];
            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.book.title),
                  subtitle: Text(book.book.author),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showBookForm(bookWithId: book),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteBook(book.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showBookForm(),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}