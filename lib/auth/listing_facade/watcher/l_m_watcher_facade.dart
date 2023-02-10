part of check_in_facade;

abstract class LMWatcherFacade {

  /// watch listing item as listing manager
  Stream<Either<ListingFormFailure, ListingManagerForm>> watchListingManagerItem({required String listingId});
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchAllListingMangerItems({required String locationIdFilter});


}