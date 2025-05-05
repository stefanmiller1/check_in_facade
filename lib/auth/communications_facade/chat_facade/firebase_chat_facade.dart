part of check_in_facade;

/// Provides access to Firebase chat data. Singleton, use
/// FirebaseChatCore.instance to aceess methods.
class FirebaseChatCore {
  FirebaseChatCore._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Config to set custom names for rooms and users collections. Also
  /// see [FirebaseChatCoreConfig].
  FirebaseChatCoreConfig config = const FirebaseChatCoreConfig(
    null,
    'rooms',
    'users',
  );

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Singleton instance.
  static final FirebaseChatCore instance = FirebaseChatCore._privateConstructor();

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => config.firebaseAppName != null
      ? FirebaseFirestore.instanceFor(app: Firebase.app(config.firebaseAppName!))
      : FirebaseFirestore.instance;
      
  FirebaseFunctions getFirebaseFunctions() => config.firebaseAppName != null
    ? FirebaseFunctions.instanceFor(app: Firebase.app(config.firebaseAppName!))
    : FirebaseFunctions.instance;

  /// Sets custom config to change default names for rooms
  /// and users collections. Also see [FirebaseChatCoreConfig].
  void setConfig(FirebaseChatCoreConfig firebaseChatCoreConfig) {
    config = firebaseChatCoreConfig;
  }

  /// Creates a chat group room with [users]. Creator is automatically
  /// added to the group. [name] is required and will be used as
  /// a group name. Add an optional [imageUrl] that will be a group avatar
  /// and [metadata] for any additional custom data.
  Future<types.Room> createGroupRoom({
    types.Role creatorRole = types.Role.admin,
    String? roomId,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    required String name,
    required List<types.User> users,
  }) async {
    if (firebaseUser == null) return Future.error('User does not exist');

    final currentUser = await fetchUser(
      getFirebaseFirestore(),
      firebaseUser!.uid,
      config.usersCollectionName,
      role: creatorRole.toShortString(),
    );

    final roomUsers = [types.User.fromJson(currentUser)] + users;

    final room = roomId != null
      ? getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId)
      : getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc();

    await room.set({
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'metadata': metadata,
      'name': name,
      'isArchive': false,
      'type': types.RoomType.group.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userIds': roomUsers.map((u) => u.id).toList(),
      'userRoles': roomUsers.fold<Map<String, String?>>({},
      (previousValue, user) => {
        ...previousValue,
        user.id: user.role?.toShortString(),
        },
      ),
    });

    return types.Room(
      id: roomId ?? room.id,
      imageUrl: imageUrl,
      metadata: metadata,
      name: name,
      type: types.RoomType.group,
      users: roomUsers,
    );
  }

/// Adds a user to an existing group chat room.
Future<void> addUserToGroupRoom({
  required String roomId,
  required String userId,
}) async {
  final fu = firebaseUser;
  if (fu == null) return Future.error("User not authenticated");

  try {
    final roomRef = getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return Future.error("Chat room does not exist");
    }

    final roomData = roomSnapshot.data();
    if (roomData == null || !roomData.containsKey('userIds') || !roomData.containsKey('userRoles')) {
      return Future.error("Invalid chat room data");
    }

    final List<dynamic> userIds = List.from(roomData['userIds']);
    final Map<String, String?> userRoles = Map<String, String?>.from(roomData['userRoles']);

    // Check if the user is already in the room
    if (userIds.contains(userId)) {
      return;
    }

    // Add the new user to the room
    userIds.add(userId);
    userRoles[userId] = types.Role.user.toShortString();

    await roomRef.update({'userIds': userIds, 'userRoles': userRoles});
  } catch (e) {
    return Future.error("Failed to add user to group room: $e");
  }
  }

/// Removes a user from a group chat room while ensuring the room remains valid.
Future<void> removeUserFromGroupRoom({
  required String roomId,
  required String userId,
}) async {
  final fu = firebaseUser;
  if (fu == null) return Future.error("User not authenticated");

  try {
    final roomRef = getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return Future.error("Chat room does not exist");
    }

    final roomData = roomSnapshot.data();
    if (roomData == null || !roomData.containsKey('userIds') || !roomData.containsKey('userRoles')) {
      return Future.error("Invalid chat room data");
    }

    List<dynamic> userIds = List.from(roomData['userIds']);
    Map<String, String?> userRoles = Map<String, String?>.from(roomData['userRoles']);

    // Check if the user is in the room
    if (!userIds.contains(userId)) {
      return Future.error("User is not in the room");
    }

    // Prevent the last user from being removed
    if (userIds.length == 1) {
      return Future.error("Cannot remove the last user from the room");
    }

    // Remove the user from the room
    userIds.remove(userId);
    userRoles.remove(userId);

    await roomRef.update({'userIds': userIds, 'userRoles': userRoles});
  } catch (e) {
    return Future.error("Failed to remove user from group room: $e");
  }
}

/// Updates a user's role to "admin" in a group chat.
Future<void> makeUserAdmin({
  required String roomId,
  required String userId,
}) async {
  final fu = firebaseUser;
  if (fu == null) return Future.error("User not authenticated");

  try {
    final roomRef = getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return Future.error("Chat room does not exist");
    }

    final roomData = roomSnapshot.data();
    if (roomData == null || !roomData.containsKey('userRoles')) {
      return Future.error("Invalid chat room data");
    }

    Map<String, String?> userRoles = Map<String, String?>.from(roomData['userRoles']);

    // Check if the user is already an admin
    if (userRoles.containsKey(userId) && userRoles[userId] == types.Role.admin.toShortString()) {
      return; // No need to update if already an admin
    }

    // Update user role to admin
    userRoles[userId] = types.Role.admin.toShortString();

    await roomRef.update({'userRoles': userRoles});
  } catch (e) {
    return Future.error("Failed to make user admin: $e");
  }
}


  Future<types.Room> createDirectRoom(
        String otherUserId,
        String roomName,
        String? imageUrl,
        {
        Map<String, dynamic>? metadata,
      }) async {
    final fu = firebaseUser;

    if (fu == null) return Future.error('User does not exist');

    final currentUser = await fetchUser(
      getFirebaseFirestore(),
      firebaseUser!.uid,
      config.usersCollectionName,
      role: types.Role.admin.toShortString(),
    );

    final otherUser = await fetchUser(
      getFirebaseFirestore(),
      otherUserId,
      config.usersCollectionName,
      role: types.Role.admin.toShortString(),
    );

    // Sort two user ids array to always have the same array for both users,
    // this will make it easy to find the room if exist and make one read only.
    final roomUsers = [types.User.fromJson(currentUser), types.User.fromJson(otherUser)];
    // Check if the room already exists
    final existingRooms = await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .where('userIds', arrayContains: fu.uid)
        .where('type', isEqualTo: types.RoomType.direct.toShortString())
        .get();

    for (var doc in existingRooms.docs) {
      final data = doc.data();
      if (data.containsKey('userIds')) {
        final List<String> existingUserIds = List<String>.from(data['userIds']);

        if (existingUserIds.toSet().containsAll(roomUsers.map((user) => user.id)) &&
            existingUserIds.length == 2) {
          // A direct message room between these users already exists, return it
          return types.Room(
            id: doc.id,
            imageUrl: data['imageUrl'],
            metadata: data['metadata'],
            name: data['name'],
            type: types.RoomType.direct,
            users: roomUsers
          );
        }
      }
    }

    // Create new room with sorted user ids array.
      final room = await getFirebaseFirestore()
        .collection(config.roomsCollectionName).add({
        'isArchive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'metadata': metadata,
        'name': roomName,
        'type': types.RoomType.direct.toShortString(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userIds': roomUsers.map((u) => u.id).toList(),
        'userRoles': roomUsers.fold<Map<String, String?>>(
        {},
            (previousValue, user) => {
            ...previousValue,
            user.id: user.role?.toShortString(),
          },
        ),
      });

      await subscribeUserToTopic(
        getFirebaseFirestore(),
        getFirebaseFunctions(),
        room.id, 
        firebaseUser!.uid,
        kIsWeb
      );
      await subscribeUserToTopic(
        getFirebaseFirestore(),
        getFirebaseFunctions(),
        room.id, 
        otherUserId,
        kIsWeb
      );

      return types.Room(
      id: room.id,
      imageUrl: imageUrl,
      metadata: metadata,
      name: roomName,
      type: types.RoomType.direct,
      users: roomUsers,
    );
  }

  /// Creates [types.User] in Firebase to store name and avatar used on
  /// rooms list
  Future<void> createUserInFirestore(types.User user) async {
    await getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .doc(user.id)
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'firstName': user.firstName,
      'imageUrl': user.imageUrl,
      'lastName': user.lastName,
      'lastSeen': FieldValue.serverTimestamp(),
      'metadata': user.metadata,
      'role': user.role?.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes message document.
  Future<void> deleteMessage(String roomId, String messageId) async {
    await getFirebaseFirestore()
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .delete();
  }

  /// Removes room document.
  Future<void> deleteRoom(String roomId) async {
    await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .delete();
  }

  /// Removes [types.User] from `users` collection in Firebase.
  Future<void> deleteUserFromFirestore(String userId) async {
    await getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .doc(userId)
        .delete();
  }


  /// Returns a stream of messages from Firebase for a given room.
  Stream<List<types.Message>> messages(
      types.Room room, {
        List<Object?>? endAt,
        List<Object?>? endBefore,
        int? limit,
        List<Object?>? startAfter,
        List<Object?>? startAt,
      }) {
    var query = getFirebaseFirestore()
        .collection('${config.roomsCollectionName}/${room.id}/messages')
        .orderBy('createdAt', descending: true);

    if (endAt != null) {
      query = query.endAt(endAt);
    }

    if (endBefore != null) {
      query = query.endBefore(endBefore);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfter(startAfter);
    }

    if (startAt != null) {
      query = query.startAt(startAt);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.fold<List<types.Message>>(
        [],
            (previousValue, doc) {
          final data = doc.data();
          final author = room.users.firstWhere(
                (u) => u.id == data['authorId'],
            orElse: () => types.User(id: data['authorId'] as String),
          );

          data['author'] = author.toJson();
          data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
          data['id'] = doc.id;
          data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

          return [...previousValue, types.Message.fromJson(data)];
        },
      ),
    );
  }

  /// Returns a stream of changes in a room from Firebase.
  Stream<types.Room> room(String roomId) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    return getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .snapshots()
        .asyncMap(
          (doc) => processRoomDocument(
        doc,
        fu,
        getFirebaseFirestore(),
        config.usersCollectionName,
      ),
    );
  }

  /// Returns a stream of rooms from Firebase. Only rooms where current
  /// logged in user exist are returned. [orderByUpdatedAt] is used in case
  /// you want to have last modified rooms on top, there are a couple
  /// of things you will need to do though:
  /// 1) Make sure `updatedAt` exists on all rooms
  /// 2) Write a Cloud Function which will update `updatedAt` of the room
  /// when the room changes or new messages come in
  /// 3) Create an Index (Firestore Database -> Indexes tab) where collection ID
  /// is `rooms`, field indexed are `userIds` (type Arrays) and `updatedAt`
  /// (type Descending), query scope is `Collection`
  Stream<List<types.Room>> rooms({bool orderByUpdatedAt = false, required types.RoomType? roomType, required bool isArchived}) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    final collection = (roomType != null) ? getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .where('userIds', arrayContains: fu.uid)
        .where('isArchive', isEqualTo: isArchived)
        .where('type', isEqualTo: roomType.toShortString())
        .orderBy('updatedAt', descending: orderByUpdatedAt) : getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .where('userIds', arrayContains: fu.uid)
        .where('isArchive', isEqualTo: isArchived)
        .orderBy('updatedAt', descending: orderByUpdatedAt);

        

    return collection.snapshots().asyncMap(
          (query) {

      return processRoomsQuery(
        fu,
        getFirebaseFirestore(),
        query,
        config.usersCollectionName,
        );
      }
    );
  }

  Stream<List<types.Room>> roomsFromReservation({required String reservationId}) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    final collection = getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .where('userIds', arrayContains: fu.uid)
        .where('metadata.reservationId', isEqualTo: reservationId);

    return collection.snapshots().asyncMap((query) {
      return processRoomsQuery(
      fu,
      getFirebaseFirestore(),
      query,
      config.usersCollectionName,
        );
      }
    );
  }


  /// Sends a message to the Firestore. Accepts any partial message and a
  /// room ID. If arbitraty data is provided in the [partialMessage]
  /// does nothing.
  void sendMessage(dynamic partialMessage, types.Message? reply, String roomId) async {
    if (firebaseUser == null) return;

    types.Message? message;

    if (partialMessage is types.PartialCustom) {
      message = types.CustomMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialCustom: partialMessage,
      );
    } else if (partialMessage is types.PartialFile) {
      message = types.FileMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialFile: partialMessage,
      );
    } else if (partialMessage is types.PartialImage) {
      message = types.ImageMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialImage: partialMessage,
      );
    } else if (partialMessage is types.PartialText) {
      message = types.TextMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialText: partialMessage,
      );
    } else if (partialMessage is types.SystemMessage) {
      message = types.SystemMessage(
        author: types.User(id: 'system'),
        text: partialMessage.text,
        id: '',
      );
    }

    if (message != null) {
      if (reply != null) {
        
        message = message.copyWith(
          repliedMessage: reply
        );
      } 
      final messageMap = message.toJson();
      messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
      messageMap['authorId'] = message.author.id;
      messageMap['createdAt'] = FieldValue.serverTimestamp();
      messageMap['updatedAt'] = FieldValue.serverTimestamp();
      messageMap['status'] = types.Status.sending.name;

  
      await getFirebaseFirestore()
          .collection('${config.roomsCollectionName}/$roomId/messages')
          .add(messageMap);
      await getFirebaseFirestore()
          .collection(config.roomsCollectionName)
          .doc(roomId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  /// Updates a message in the Firestore. Accepts any message and a
  /// room ID. Message will probably be taken from the [messages] stream.
  void updateMessage(types.Message message, String roomId) async {
    if (firebaseUser == null) return;
    // if (message.author.id != firebaseUser!.uid) return;

    final currentUserId = firebaseUser!.uid;
    final messageMap = message.toJson();
    messageMap.removeWhere(
          (key, value) => key == 'author' || key == 'createdAt' || key == 'id',
    );
    messageMap['authorId'] = message.author.id;
    messageMap['updatedAt'] = FieldValue.serverTimestamp();
    // Ensure userStatus is stored as a map in metadata and only update for the current user
  final Map<String, String> updatedUserStatus = Map<String, String>.from(message.metadata?['userStatus'] ?? {});
  updatedUserStatus[currentUserId] = types.Status.seen.name;

  messageMap['metadata'] = {
    ...message.metadata ?? {},
    'userStatus': updatedUserStatus,
  };


    await getFirebaseFirestore()
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(message.id)
        .update(messageMap);
  }

  /// Updates a room in the Firestore. Accepts any room.
  /// Room will probably be taken from the [rooms] stream.
  void updateRoom(types.Room room) async {
    if (firebaseUser == null) return;

    final roomMap = room.toJson();
    roomMap.removeWhere((key, value) =>
    key == 'createdAt' ||
        key == 'id' ||
        key == 'lastMessages' ||
        key == 'users');

    if (room.type == types.RoomType.direct) {
      roomMap['imageUrl'] = null;
      roomMap['name'] = null;
    }

    roomMap['lastMessages'] = room.lastMessages?.map((m) {
      final messageMap = m.toJson();

      messageMap.removeWhere((key, value) =>
      key == 'author' ||
          key == 'createdAt' ||
          key == 'id' ||
          key == 'updatedAt');

      messageMap['authorId'] = m.author.id;

      return messageMap;
    }).toList();
    roomMap['updatedAt'] = FieldValue.serverTimestamp();
    roomMap['userIds'] = room.users.map((u) => u.id).toList();

    await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(room.id)
        .update(roomMap);
  }

  /// Returns a stream of all users from Firebase.
  Stream<List<types.User>> users() {
    if (firebaseUser == null) return const Stream.empty();
    return getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<List<types.User>>(
        [],
            (previousValue, doc) {
          if (firebaseUser!.uid == doc.id) return previousValue;

          final data = doc.data();

          data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
          data['id'] = doc.id;
          data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
          data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

          return [...previousValue, types.User.fromJson(data)];
        },
      ),
    );
  }



  /// send notification to everyone in room
  void sendDirectNotifications(List<String> userIds, String sentFromName, types.PartialText textMessage, String route, Map<String, dynamic> metaData) async  {
  if (firebaseUser == null) return;


      for (String userId in userIds) {
        if (userId == firebaseUser?.uid) return;
        final userInfo = await getFirebaseFirestore().collection(config.usersCollectionName).doc(userId).get();

        final UniqueId notificationId = UniqueId();
        final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: firebaseUser?.uid, notificationType: AccountNotificationType.message.toString()).toJson();

        
        sendPushNotification(
            getFirebaseFirestore(),
            getFirebaseFunctions(),
            userId,
            metaData,
            route,
            '$sentFromName Sent you a message',
            textMessage.text,
            textMessage.previewData?.image?.url
        );
      }
  }
  /// Retrieves all users in a room.
  Future<List<types.User>> getUsersInRoom(String roomId) async {
    final roomRef = getFirebaseFirestore().collection(config.roomsCollectionName).doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return [];
    }

    final roomData = roomSnapshot.data();
    if (roomData == null || !roomData.containsKey('userIds')) {
      return [];
    }

    final List<String> userIds = List<String>.from(roomData['userIds']);
    final List<types.User> users = [];

    for (final userId in userIds) {
      final doc = await getFirebaseFirestore()
          .collection(config.usersCollectionName)
          .doc(userId)
          .get();

          if (doc.exists) {
            final data = doc.data();

            if (data != null) {
              // Map Firebase fields to types.User fields
            final user = types.User(
              id: doc.id,
              firstName: data['legalName'] ?? '',
              lastName: data['legalSurname'] ?? '', 
              imageUrl: data['photoUri'] ?? '',
            );

              users.add(user);
            }
          }
    }

    return users;
  }
}