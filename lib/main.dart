import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucas_paul_movie_explorer/class/Movie.dart';
import 'package:http/http.dart' as http;

import 'dart:async';

int currentPage = 1;
late Future<List<Movie>> futureMovies;
List<Movie> favoriteMovies = [];
String api_key = "your_api_key_here"; // Remplace par ta propre clé API TMDB
TextEditingController searchController = TextEditingController();
Future<List<Movie>>? searchResults;

class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const MovieCard({
    super.key,
    required this.movie,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    
    return Card(
      child: ListTile(
        leading: Image.network(movie.poster, width: 50, fit: BoxFit.cover),
        title: Text("${movie.title} ${movie.year}"),
        subtitle: Text(movie.description),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : null,
          ),
          onPressed: onFavoriteToggle,
        ),
      ),
    );
  }
}


void main() => runApp(const NavigationBarApp());
class NavigationBarApp extends StatelessWidget {
  
  
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return const MaterialApp(home: NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {

  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=$api_key&language=fr-FR&query=$query',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List results = data['results'];

      return results.map((movieJson) {
        return Movie(
          title: movieJson['title'],
          year: movieJson['release_date'] != null &&
                  movieJson['release_date'].isNotEmpty
              ? int.parse(movieJson['release_date'].substring(0, 4))
              : 0,
          description: movieJson['overview'],
          poster: movieJson['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${movieJson['poster_path']}'
              : 'https://via.placeholder.com/100x150',
        );
      }).toList();
    } else {
      throw Exception('Erreur API');
    }
  }

  Future<List<Movie>> fetchMovies(int page) async {
  final url = Uri.parse(
    'https://api.themoviedb.org/3/discover/movie?api_key=$api_key&language=fr-FR&page=$page',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    List results = data['results'];

    return results.map((movieJson) {
      return Movie(
        title: movieJson['title'],
        year: int.parse(movieJson['release_date'].substring(0, 4)),
        description: movieJson['overview'],
        poster:
            'https://image.tmdb.org/t/p/w500${movieJson['poster_path']}',
      );
    }).toList();
  } else {
    throw Exception('Erreur API');
  }
}

  int currentPageIndex = 0;
  @override
  void initState() {
    super.initState();
    futureMovies = fetchMovies(currentPage);
  }

  @override
  Widget build(BuildContext context) {


    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),



      body: <Widget>[
        /// Home page
        Column(
          children: [
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: futureMovies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else {
                  final movies = snapshot.data!;
                  movies.sort((a, b) => b.year.compareTo(a.year));

                  return ListView.builder(
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      return MovieCard(
                        movie: movies[index],
                        isFavorite: favoriteMovies.contains(movies[index]),
                        onFavoriteToggle: () {
                          setState(() {
                            if (favoriteMovies.contains(movies[index])) {
                              favoriteMovies.remove(movies[index]);
                            } else {
                              favoriteMovies.add(movies[index]);
                            }
                          });
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),

          /// 🔽 Boutons pagination
          Padding(
          padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1
                      ? () {
                          setState(() {
                            currentPage--;
                            futureMovies = fetchMovies(currentPage);
                          });
                        }
                      : null,
                  child: const Text('Précédent'),
                ),

                Text('Page $currentPage'),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentPage++;
                      futureMovies = fetchMovies(currentPage);
                    });
                  },
                  child: const Text('Suivant'),
                ),
              ],
            ),
          ),
          ],
        ),
  
        /// Notifications page
        favoriteMovies.isEmpty? const Center(child: Text("Aucun favori")): ListView.builder(
          itemCount: favoriteMovies.length,
          itemBuilder: (context, index) {
            return MovieCard(
              movie: favoriteMovies[index],
              isFavorite: true,
              onFavoriteToggle: () {
                setState(() {
                  favoriteMovies.remove(favoriteMovies[index]);
                });
              },
            );
          },
        ),

        /// Messages page
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un film...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        searchResults = searchMovies(searchController.text);
                      });
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  setState(() {
                    searchResults = searchMovies(value);
                  });
                },
              ),
            ),

            Expanded(
              child: searchResults == null? const Center(child: Text("Tape un film à rechercher")): FutureBuilder<List<Movie>>(
                future: searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  } else {
                    final movies = snapshot.data!;

                    if (movies.isEmpty) {
                      return const Text("Aucun résultat");
                    }

                    return ListView.builder(
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        return MovieCard(
                          movie: movies[index],
                          isFavorite: favoriteMovies.contains(movies[index]),
                          onFavoriteToggle: () {
                            setState(() {
                              if (favoriteMovies.contains(movies[index])) {
                                favoriteMovies.remove(movies[index]);
                              } else {
                                favoriteMovies.add(movies[index]);
                              }
                            });
                          },
                        );
                      },
                    );
                  }
                },
                    ),
                  ),
                ],
              
        )
      ][currentPageIndex],
    );
  }
}
// void main() {
  

//   runApp(const MyApp());
// }