part of check_in_facade;

@LazySingleton(as: LMWatcherFacade)
class ListingManagerWatcherFacade implements LMWatcherFacade {

  final FirebaseFirestore _fireStore;

  ListingManagerWatcherFacade(this._fireStore);


  @override
  Stream<Either<ListingFormFailure, ListingManagerForm>> watchListingManagerItem({required String listingId}) async* {

    try {

      yield* _fireStore.collection('listing_directory')
      .doc(listingId)
      .snapshots()
      .map((event) {

        if (event.exists) {
          return right<ListingFormFailure, ListingManagerForm>(ListingManagerFormDto.fromFireStore(event).toDomain());
        } else {
          return left(ListingFormFailure.doesNotExist());
        }
      });

      yield left(ListingFormFailure.listingServerError());
    } catch (e) {
      yield left(ListingFormFailure.listingServerError());
    }
  }

  @override
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchAllListingMangerItems({required List<String>? listingIdFilterBy}) async* {

    try {

      final listingRef = _fireStore.collection('listing_directory');
      if (listingIdFilterBy?.isNotEmpty ?? false) listingRef.where('listingServiceId', whereIn: listingIdFilterBy?.toList());
      
      yield* listingRef.snapshots()
          .map((event) {

            if (event.docs.isNotEmpty) {
              return right<ListingFormFailure, List<ListingManagerForm>>(event.docs.map((listing) => ListingManagerFormDto.fromFireStore(listing).toDomain()).toList());
            } else {
              return left(ListingFormFailure.listingsNotFound());
          }
        }
      );

      yield left(ListingFormFailure.listingServerError());
    } catch (e) {
      yield left(ListingFormFailure.listingServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchSearchedListingItems(List<String>? countriesFilter, String? city, String? stateProvince, bool? isVerified) async* {
    try {

      final listingRef = _fireStore.collection('listing_directory');
      if (countriesFilter?.isNotEmpty ?? false) listingRef.where('listingProfileService.backgroundInfoServices.listingLocationSetting.countryRegion', whereIn: countriesFilter);
      if (city != null) listingRef.where('listingProfileService.backgroundInfoServices.listingLocationSetting.city', isEqualTo: countriesFilter);
      if (stateProvince != null) listingRef.where('listingProfileService.backgroundInfoServices.listingLocationSetting.provinceState', isEqualTo: stateProvince);

      yield* listingRef.snapshots()
          .map((event) {
        if (event.docs.isNotEmpty) {
          return right<ListingFormFailure, List<ListingManagerForm>>(event.docs.map((listing) => ListingManagerFormDto.fromFireStore(listing).toDomain()).toList());
        } else {
          return left(ListingFormFailure.listingsNotFound());
        }
      }
      );


      yield left(ListingFormFailure.listingServerError());
    } catch (e) {
      yield left(ListingFormFailure.listingServerError(failed: e.toString()));
    }
  }
}

