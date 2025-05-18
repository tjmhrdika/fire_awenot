class Book {
  final String title;
  final String author;

  Book({required this.title, required this.author});

  Map<String, dynamic> toMap() => {
    'title': title,
    'author': author,
  };

  static Book fromMap(Map<String, dynamic> map) => Book(
    title: map['title'] ?? '',
    author: map['author'] ?? '',
  );
}

class BookWithId {
  final String id;
  final Book book;

  BookWithId({required this.id, required this.book});
}