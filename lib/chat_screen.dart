import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart'; 

class ChatScreen extends StatelessWidget {
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Chat', style: TextStyle(fontFamily: 'Roboto', fontSize: 24)),
        backgroundColor: const Color.fromARGB(255, 52, 159, 247),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false, // Elimina todas las rutas en el stack
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!chatSnapshot.hasData || chatSnapshot.data == null) {
                  return Center(child: Text('No messages yet.'));
                }
                final chatDocs = chatSnapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final message = chatDocs[index]['text'];
                    if (message.startsWith('Location:')) {
                      final locationUrl =
                          message.substring('Location: '.length);
                      return ListTile(
                        title: GestureDetector(
                          child: Text.rich(
                            TextSpan(
                              text: locationUrl,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          onTap: () {
                            _openMap(locationUrl);
                          },
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(message),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(labelText: 'Send a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('messages')
                          .add({
                        'text': messageController.text,
                        'createdAt': Timestamp.now(),
                        'userId': user.uid,
                      });
                      messageController.clear();
                    } else {
                      print('No user is signed in.');
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high);
                      final googleMapsUrl =
                          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
                      await FirebaseFirestore.instance
                          .collection('messages')
                          .add({
                        'text': 'Location: $googleMapsUrl',
                        'createdAt': Timestamp.now(),
                        'userId': user.uid,
                      });
                    } else {
                      print('No user is signed in.');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMap(String locationUrl) async {
    if (await canLaunch(locationUrl)) {
      await launch(locationUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
