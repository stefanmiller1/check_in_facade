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
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchSearchedListingItems(List<ManagerListingStatusType> status, String? country, String? city, bool? isVerified) async* {
    try {

      var listingRef = _fireStore.collection('listing_directory')
          .where('listingProfileService.backgroundInfoServices.listingStatus', whereIn: status.map((e) => e.toString()).toList());

      // retrieve only verified locations
      if (isVerified == true) {
        listingRef = listingRef.where('listingProfileService.listingLocationSetting.isVerified', isEqualTo: true);
      }

      if (country != null && country != '') {
        listingRef = listingRef.where('listingProfileService.listingLocationSetting.countryRegion', isEqualTo: country);
      }

      if (city != null && city != '') {
        listingRef = listingRef.where('listingProfileService.listingLocationSetting.city', isEqualTo: city);
      }

      /// implement an order by - based on review
      /// number of reservations booked

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

