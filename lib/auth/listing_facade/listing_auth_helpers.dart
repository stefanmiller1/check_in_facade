part of check_in_facade;

extension ListingFireStoreX on FirebaseFirestore {

  Future<DocumentReference> listingDocument(String listingId) async {
    return FirebaseFirestore.instance.collection('listing_directory').doc(listingId);
  }

}

extension ListingDocumentReferenceX on DocumentReference {

  CollectionReference get listingDocuments => collection('listing_reservations');

}