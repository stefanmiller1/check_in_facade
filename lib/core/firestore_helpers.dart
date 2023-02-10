part of check_in_facade;

extension FireStoreUserX on FirebaseFirestore {

  Future<DocumentReference> userDocument() async {

    final userOption = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance.collection('users').doc(userOption!.uid);
  }

}

extension DocumentReferenceX on DocumentReference {

  CollectionReference get sessionDocument => collection('sessions_form');
  CollectionReference get locationsDocument => collection('locations_form');
  CollectionReference get facilityDocument => collection('facility_form');

}
