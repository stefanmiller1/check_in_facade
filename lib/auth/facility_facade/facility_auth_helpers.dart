part of check_in_facade;

extension FacilityFireStorX on FirebaseFirestore {

  Future<DocumentReference> facilityDocument(String facilityId) async {
    return FirebaseFirestore.instance.collection('listing_directory').doc(facilityId);
  }

  Future<DocumentReference> locationsDocument(String locationId) async {
    return FirebaseFirestore.instance.collection('location_directory').doc(locationId);
  }

  Future<DocumentReference> activityDocument(String activityId) async {
    return FirebaseFirestore.instance.collection('activity_directory').doc(activityId);
  }

}

extension FacilityDocumentReferenceX on DocumentReference {

    // CollectionReference get facilityFormDocuments => collection('facility_form');
    CollectionReference get facilitySecurityCodeDocuments => collection('security_forms');
    CollectionReference get facilityPermitDocuments => collection('permit_forms');
    CollectionReference get facilityInsuranceDocuments => collection('insurance_forms');
    CollectionReference get facilityPaymentDocuments => collection('payment_forms');
    CollectionReference get facilityActivityBookingDocuments => collection('activity_bookings');
    CollectionReference get facilityCheckInFormDocuments => collection('check_in_forms');
}

extension ActivityDocumentReferenceX on DocumentReference {

  CollectionReference get activityFormDocument => collection('activity_form');


}