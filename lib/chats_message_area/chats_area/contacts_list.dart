import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whats_app/models/user_model.dart';

class ContactsList extends StatefulWidget
{
const ContactsList({super.key});

@override
State<ContactsList> createState() => _ContactsListState();
}



class _ContactsListState extends State<ContactsList>
{
  String currentUserID = "";

  getCurrentFirebaseUser()
  {
    User currentFirebaseUser = FirebaseAuth.instance.currentUser!;
    if(currentFirebaseUser != null)
    {
      currentUserID = currentFirebaseUser.uid;
    }
  }

  Future<List<UserModel>> readContactsList() async
  {
    final usersRef = FirebaseFirestore.instance.collection("users");

    QuerySnapshot allUsersRecord = await usersRef.get();

    List<UserModel> allUsersList = [];

    for(DocumentSnapshot userRecord in allUsersRecord.docs)
    {
      String uid = userRecord["uid"];
      if(uid == currentUserID)
      {
        continue;
      }

      String name = userRecord["name"];
      String email = userRecord["email"];
      String password = userRecord["password"];
      String image = userRecord["image"];

      UserModel userData = UserModel(uid, name, email, password, image: image);

      allUsersList.add(userData);
    }

    return allUsersList;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCurrentFirebaseUser();
  }

  @override
  Widget build(BuildContext context)
  {
    return FutureBuilder(
      future: readContactsList(),
      builder: (context, dataSnapshot)
      {
        switch(dataSnapshot.connectionState)
        {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Padding(
              padding: EdgeInsets.all(18.0),
              child: Center(
                child: Column(
                  children: [

                    Text("loading contacts"),
                    SizedBox(height: 10,),
                    CircularProgressIndicator(),

                  ],
                ),
              ),
            );

          case ConnectionState.active:
          case ConnectionState.done:
            if(dataSnapshot.hasError)
            {
              return const Center(
                child: Text(
                  "Error on loading Contacts List",
                ),
              );
            }
            else
            {
              List<UserModel>? userContactsList = dataSnapshot.data;

              if(userContactsList != null)
              {
                return ListView.separated(
                  separatorBuilder: (context, index)
                  {
                    return const Divider(
                      thickness: 0.3,
                      color: Colors.grey,
                    );
                  },
                  itemCount: userContactsList.length,
                  itemBuilder: (context, index)
                  {
                    UserModel userData = userContactsList[index];

                    return ListTile(
                      onTap: ()
                      {
                        Future.delayed(Duration.zero, ()
                        {
                          Navigator.pushNamed(
                            context,
                            "/messages",
                            arguments: userData,
                          );
                        });
                      },
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey,
                        backgroundImage: NetworkImage(userData.image.toString()),
                      ),
                      title: Text(
                        userData.name.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(9),
                    );
                  },
                );
              }
              else
              {
                return const Center(
                  child: Text(
                    "No contact found",
                  ),
                );
              }
            }
        }
      },
    );
  }
}
