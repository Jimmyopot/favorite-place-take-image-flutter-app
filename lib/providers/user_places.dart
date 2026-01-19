
import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  return sql.openDatabase(path.join(dbPath, 'places.db'),
      onCreate: (db, version) {
    return db.execute(
        'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT, lat REAL, lng REAL, address TEXT)');
  }, version: 1);
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places');

    final places = data.map((item) {
      return Place(
        id: item['id'] as String,
        title: item['title'] as String,
        image: File(item['image'] as String),
        location: item['lat'] != null && item['lng'] != null
            ? PlaceLocation(
                latitude: item['lat'] as double,
                longitude: item['lng'] as double,
                address: item['address'] as String?,
              )
            : null,
      );
    }).toList();

    state = places;
  }
  void addPlace(String title, File? image, PlaceLocation? location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final filename = path.basename(image!.path);
    final copiedImage = await image.copy('${appDir.path}/$filename');

    final newPlace = Place(title: title, image: copiedImage, location: location);

    final db = await _getDatabase();
    await db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': copiedImage.path,
      'lat': location?.latitude,
      'lng': location?.longitude,
      'address': location?.address,
    });

    state = [...state, newPlace];
  }
}

final userPlacesProvider = StateNotifierProvider<UserPlacesNotifier, List<Place>>(
        (ref) => UserPlacesNotifier()
    );