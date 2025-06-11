import 'package:flutter/material.dart';
import '../models/meals.dart';
import '../widgets/meal_search_delegate.dart';
import 'package:habitfit_new/meal_info_screen.dart';

class EatingHabitsScreen extends StatefulWidget {
  const EatingHabitsScreen({super.key});

  @override
  State<EatingHabitsScreen> createState() => _EatingHabitsScreenState();
}

class _EatingHabitsScreenState extends State<EatingHabitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eating Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealInfoScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildTargetCalories(),
              const SizedBox(height: 20),
              ...['Breakfast', 'Lunch', 'Dinner'].map((type) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildMealList(type),
                  const SizedBox(height: 20),
                ],
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      readOnly: true,
      onTap: () async {
        await showSearch(
          context: context,
          delegate: MealSearchDelegate(onMealSelected: (Meal? selectedMeal) {
            if (selectedMeal != null) {
              final newMeal = Meal(
                id: '',
                name: selectedMeal.name,
                calories: selectedMeal.calories,
                mealType: 'Breakfast',
                date: DateTime.now(),
              );
              _showAddMealDialog(context, preset: newMeal);
            }
          }),
        );
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search food...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTargetCalories() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Target Calories: 2000 kcal',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildMealList(String mealType) {
    return FutureBuilder<List<Meal>>(
      future: Meal.fetchFromFirestore(mealType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Error loading meals.',
              style: TextStyle(color: Colors.red));
        }

        final meals = snapshot.data ?? [];
        if (meals.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No meals added yet.',
                style: TextStyle(color: Colors.white60)),
          );
        }

        return ListView.builder(
          itemCount: meals.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => _buildMealTile(meals[index]),
        );
      },
    );
  }

  Widget _buildMealTile(Meal meal) {
    return Card(
      color: Colors.black54,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const Icon(Icons.restaurant_menu, color: Colors.blue),
        title: Text(meal.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          '${meal.calories} kcal\n${meal.date.toLocal().toString().split(".").first}',
          style: const TextStyle(height: 1.4),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddMealDialog(context, preset: meal);
            } else if (value == 'delete') {
              _deleteMeal(meal);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _deleteMeal(Meal meal) async {
    await Meal.deleteFromFirestore(meal.id);
    setState(() {});
  }

  void _showAddMealDialog(BuildContext context, {Meal? preset}) {
    final nameController = TextEditingController(text: preset?.name ?? '');
    final calorieController =
    TextEditingController(text: preset?.calories.toString() ?? '');
    String selectedMealType = preset?.mealType ?? 'Breakfast';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(preset == null ? 'Add Meal' : 'Edit Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Meal Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: calorieController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedMealType,
                items: ['Breakfast', 'Lunch', 'Dinner']
                    .map((meal) =>
                    DropdownMenuItem(value: meal, child: Text(meal)))
                    .toList(),
                onChanged: (value) => selectedMealType = value ?? 'Breakfast',
                decoration: const InputDecoration(labelText: 'Meal Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final calories =
                    int.tryParse(calorieController.text.trim()) ?? 0;
                if (name.isEmpty || calories <= 0) return;

                final meal = Meal(
                  id: preset?.id ?? '',
                  name: name,
                  calories: calories,
                  mealType: selectedMealType,
                  date: DateTime.now(),
                );

                await Meal.addToFirestore(meal);
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(preset == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
