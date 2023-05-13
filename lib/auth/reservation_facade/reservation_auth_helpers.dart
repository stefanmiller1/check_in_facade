part of check_in_facade;

extension ReservationFireStoreX on FirebaseFirestore {

  Future<DocumentReference> reservationDocument(String reservationId) async {
    return FirebaseFirestore.instance.collection('reservation_directory').doc(reservationId);
  }

  Future<DocumentReference> reservationPostDocument(String postId) async {
    return FirebaseFirestore.instance.collection('reservation_post').doc(postId);
  }

}

extension ReservationDocumentReferenceX on DocumentReference {

  CollectionReference get reservationRequestDocuments => collection('requests');

}