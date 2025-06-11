import 'package:flutter/material.dart';

class MealInfoScreen extends StatelessWidget {
  const MealInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Understanding Calories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Calories represent the energy that food provides. The average daily intake is around 2000 kcal, but it varies depending on age, gender, and activity level.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Examples of Common Foods:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('🍚 Nasi Putih (1 cup): ~200 kcal'),
            Text('🍗 Fried Chicken (thigh): ~280 kcal'),
            Text('🥚 Boiled Egg: ~78 kcal'),
            Text('🍌 Banana: ~89 kcal'),
            Text('🥤 Teh Tarik (sweet): ~130 kcal'),
            SizedBox(height: 20),
            Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('✅ Balance your calories between meals.'),
            Text('✅ Avoid sugary drinks and snacks.'),
            Text('✅ Use the search to estimate unknown items.'),
          ],
        ),
      ),
    );
  }
}
