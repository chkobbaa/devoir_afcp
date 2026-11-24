import 'package:auth/user.dart';
import 'package:auth/etudiants_screen.dart';
import 'package:auth/classes_screen.dart';
import 'package:auth/absences_screen.dart';
import 'package:auth/reference_data_screen.dart';
import 'package:auth/prevision_absences_screen.dart';
import 'package:auth/plus_etudiants_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatefulWidget {
  final User user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // 0 = home, 1 = absences, 2 = etudiants, 3 = classes, 4 = formations,
  // 5 = departments, 6 = subjects, 7 = users, 8 = class-subject links
  int _selectedIndex = 1; // default to Absences screen for TP7 suite!

  Widget _buildHome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 80, color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            "Welcome!",
            style: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            "Use the drawer to manage students, classes and formations.",
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _currentScreen() {
    switch (_selectedIndex) {
      case 1:
        return const AbsencesScreen();
      case 2:
        return const EtudiantsScreen();
      case 3:
        return const ClassesScreen();
      case 4:
        return const ReferenceDataScreen(kind: ReferenceKind.formations);
      case 5:
        return const ReferenceDataScreen(kind: ReferenceKind.departments);
      case 6:
        return const ReferenceDataScreen(kind: ReferenceKind.subjects);
      case 7:
        return const ReferenceDataScreen(kind: ReferenceKind.users);
      case 8:
        return const ReferenceDataScreen(kind: ReferenceKind.classSubjects);
      case 9:
        return const PrevisionAbsencesScreen();
      case 10:
        return const PlusEtudiantsScreen();
      default:
        return _buildHome();
    }
  }

  String _title() {
    switch (_selectedIndex) {
      case 1:
        return "Gestion des Absences";
      case 2:
        return "Student Management";
      case 3:
        return "Class Management";
      case 4:
        return "Formation Management";
      case 5:
        return "Gestion des départements";
      case 6:
        return "Gestion des matières";
      case 7:
        return "Gestion des utilisateurs";
      case 8:
        return "Matières par classe";
      case 9:
        return "Prévision des absences";
      case 10:
        return "Classe avec le plus d’étudiants";
      default:
        return "Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(),
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.purple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.purple),
              title: const Text("Gestion des Absences"),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Etudiants"),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.purple),
              title: const Text("Relevés de Notes"),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text("Classes"),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Formations"),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree, color: Colors.purple),
              title: const Text("Départements"),
              selected: _selectedIndex == 5,
              onTap: () { setState(() => _selectedIndex = 5); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.purple),
              title: const Text("Matières"),
              selected: _selectedIndex == 6,
              onTap: () { setState(() => _selectedIndex = 6); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.purple),
              title: const Text("Utilisateurs"),
              selected: _selectedIndex == 7,
              onTap: () { setState(() => _selectedIndex = 7); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.purple),
              title: const Text("Matières par classe (Coef / CHSM)"),
              selected: _selectedIndex == 8,
              onTap: () { setState(() => _selectedIndex = 8); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.query_stats, color: Colors.purple),
              title: const Text("Prévoir les absences"),
              selected: _selectedIndex == 9,
              onTap: () { setState(() => _selectedIndex = 9); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.groups, color: Colors.purple),
              title: const Text("Classe avec le plus d’étudiants"),
              selected: _selectedIndex == 10,
              onTap: () { setState(() => _selectedIndex = 10); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pop(context); // go back to login
              },
            ),
          ],
        ),
      ),
      body: _currentScreen(),
    );
  }
}

