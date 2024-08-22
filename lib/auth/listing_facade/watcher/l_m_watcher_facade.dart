part of check_in_facade;

abstract class LMWatcherFacade {

  /// watch listing item as listing manager
  Stream<Either<ListingFormFailure, ListingManagerForm>> watchListingManagerItem({required String listingId});
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchAllListingMangerItems({required List<String>? listingIdFilterBy});
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchSearchedListingItems(List<ManagerListingStatusType> status, String? country, String? city, bool? isVerified);
  Stream<Either<ListingFormFailure, List<ListingManagerForm>>> watchUsersListingItems({required List<ManagerListingStatusType> status, required String? userId, required bool? isVerified});

}