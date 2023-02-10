part of check_in_facade;

extension ReservationFireStoreX on FirebaseFirestore {

  Future<DocumentReference> reservationDocument(String listingId) async {
    return FirebaseFirestore.instance.collection('reservation_directory').doc(listingId);
  }

}

extension ReservationDocumentReferenceX on DocumentReference {

  CollectionReference get reservationRequestDocuments => collection('requests');

}