part of check_in_facade;

@LazySingleton(as: LMFacade)
class ListingManagerFacade implements LMFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final LocationAuthFacade _locationFacade;

  ListingManagerFacade(this._fireStore, this._firebaseAuth, this._locationFacade);


  @override
  Future<Either<ListingFormFailure, Unit>> updateListingForm({required ListingManagerForm listingForm}) async {

    try {

      final listingDoc = await _fireStore.listingDocument(listingForm.listingServiceId.getOrCrash());

      final listingFormDto = ListingManagerFormDto.fromDomain(listingForm).toJson();
      listingDoc.update(listingFormDto);

      return right(unit);
    } catch (e) {
      return left(ListingFormFailure.listingServerError(failed: e.toString()));
    }

  }

}