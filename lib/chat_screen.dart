import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatelessWidget {
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).snapshots(),
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
                    print('Message: $message');  // Debugging line
                    if (message.startsWith('Location:')) {
                      final location = message.substring('Location: '.length);
                      final latLng = location.split(',');
                      print('Location: $location');  // Debugging line
                      if (latLng.length == 2) {
                        try {
                          final latitude = double.parse(latLng[0]);
                          final longitude = double.parse(latLng[1]);
                          return ListTile(
                            title: Text('Location: $latitude, $longitude'),
                            onTap: () {
                              _openMap(latitude, longitude);
                            },
                          );
                        } catch (e) {
                          print('Error parsing location: $e');  // Debugging line
                          return ListTile(
                            title: Text('Invalid location format'),
                          );
                        }
                      } else {
                        return ListTile(
                          title: Text('Invalid location format'),
                        );
                      }
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
                      await FirebaseFirestore.instance.collection('messages').add({
                        'text': messageController.text,
                        'createdAt': Timestamp.now(),
                        'userId': user.uid,
                      });
                      messageController.clear();
                    } else {
                      // Manejar el caso de usuario no autenticado
                      print('No user is signed in.');
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      await FirebaseFirestore.instance.collection('messages').add({
                        'text': 'Location: ${position.latitude},${position.longitude}',
                        'createdAt': Timestamp.now(),
                        'userId': user.uid,
                      });
                    } else {
                      // Manejar el caso de usuario no autenticado
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

  void _openMap(double latitude, double longitude) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
