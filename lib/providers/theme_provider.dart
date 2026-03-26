import 'package:flutter/material.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:provider/provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
    //scaffoldBackgroundColor: const Color.fromARGB(255, 28, 28, 28),
    colorScheme: ColorScheme.light(
      primary: Colors.black87,
      inversePrimary: Colors.white,
      secondary: Color.fromARGB(255, 231, 231, 231),
      onSecondary: Color.fromARGB(255, 243, 243, 243),
      tertiary: Color.fromARGB(255, 150, 150, 150),
      surface: Color.fromARGB(255, 85, 85, 85),
      scrim: Color.fromARGB(175, 203, 199, 205),
      shadow: Color.fromARGB(85, 160, 160, 160),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.white),
      headlineMedium: TextStyle(color: AppColors.textTetiary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall: TextStyle(color: Color.fromARGB(255, 192, 192, 192)),
    ),
    useMaterial3: true,
  );

  ThemeData get darkTheme => ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Color.fromARGB(255, 75, 75, 75),
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      inversePrimary: Colors.black,
      secondary: Color.fromARGB(255, 75, 75, 75),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textSecondary),
      bodyLarge: TextStyle(color: AppColors.white),
      bodyMedium: TextStyle(color: AppColors.textTetiary),
      bodySmall: TextStyle(color: Color.fromARGB(255, 173, 173, 173)),
    ),
    useMaterial3: true,
  );
}

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.light_mode),
        Switch(
          value: isDark,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
        ),
        const Icon(Icons.dark_mode),
      ],
    );
  }
}
