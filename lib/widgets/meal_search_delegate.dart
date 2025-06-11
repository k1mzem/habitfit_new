import 'package:flutter/material.dart';
import '../models/meals.dart';

class MealSearchDelegate extends SearchDelegate<Meal?> {
  final void Function(Meal?) onMealSelected;

  MealSearchDelegate({required this.onMealSelected});

  List<Meal> _allMeals = [];

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<Meal>>(
      future: Meal.fetchAllFromFirestore(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        _allMeals = snapshot.data!;
        final suggestions = _allMeals
            .where((meal) => meal.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return ListView.separated(
          itemCount: suggestions.length + 1, // +1 for the manual entry link
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // Last item = "Can't find your meal?"
            if (index == suggestions.length) {
              return ListTile(
                title: RichText(
                  text: const TextSpan(
                    text: "Can't find your meal? ",
                    style: TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                        text: 'Tap here',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  close(context, null);
                  onMealSelected(null); // trigger fallback manual dialog
                },
              );
            }

            final meal = suggestions[index];
            return ListTile(
              title: Text(meal.name),
              subtitle: Text('${meal.calories} kcal'),
              onTap: () {
                final clonedMeal = Meal(
                  id: '', // new ID = new document
                  name: meal.name,
                  calories: meal.calories,
                  mealType: 'Breakfast', // default
                  date: DateTime.now(),
                );
                close(context, clonedMeal);
                onMealSelected(clonedMeal);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => const SizedBox.shrink();

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }
}
