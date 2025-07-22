import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:twasol/screens/chat.dart';
import 'package:twasol/screens/login.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);
  static const String id = 'Home';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance?.addObserver(this);

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in, update online status to true
        _updateUserOnlineStatus(true);
      } else {
        // User is signed out, update online status to false
        _updateUserOnlineStatus(false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      // Update online status to false and sign out
        _updateUserOnlineStatus(false);
        _auth.signOut();
        break;
      case AppLifecycleState.resumed:
      // Attempt to sign in the user if not already signed in
        if (_auth.currentUser == null) {
          // Perform your logic to sign in the user
          // For example, you can navigate to the login screen
          Navigator.pushNamed(context, Login.id);
        }
        break;
      case AppLifecycleState.detached:
      // Handle cleanup or additional actions on app detachment
        break;
      default:
        break;
    }
  }

  void _updateUserOnlineStatus(bool online) async {
    try {
      // Check if the user is authenticated before updating online status
      if (_auth.currentUser != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(_auth.currentUser!.uid)
            .update({"online": online});
      }
    } catch (e) {
      print("Error updating online status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[300],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DayNightSwitcher(
                isDarkModeEnabled: AdaptiveTheme.of(context).mode.isDark,
                onStateChanged: (isDarkModeEnabled) {
                  if (isDarkModeEnabled) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: Colors.black,
                  size: 35,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, Login.id);
                },
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Container(
              color: Colors.grey[300],
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Online'),
                  Tab(text: 'Offline'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUserList(online: true),
            _buildUserList(online: false),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({required bool online}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading..');
        }

        var allUsers = snapshot.data!.docs;

        var filteredUsers = allUsers.where((doc) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('online')) {
            bool isOnline = data['online'] as bool? ?? false;
            return isOnline == online;
          }

          return false;
        }).toList();

        List<Widget> userWidgets = filteredUsers
            .where((doc) => _auth.currentUser!.email != doc['email'])
            .map<Widget>((doc) {
          Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

          return ListTile(
            leading: Icon(
              Icons.person,
              color: Colors.grey,
            ),
            title: Text(
              data['email'],
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => chat(
                    receiverUserEmail: data['email'],
                    receiverUserID: data['uid'],
                  ),
                ),
              );
            },
          );
        }).toList();

        return ListView(
          children: userWidgets,
        );
      },
    );
  }
}
