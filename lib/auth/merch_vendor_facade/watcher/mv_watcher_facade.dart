part of check_in_facade;

abstract class MVAuthWatcherFacade {

  Stream<Either<ProfileValueFailure, List<EventMerchantVendorProfile>>> watchEventMerchByFilter({required List<MerchantVendorTypes>? merchType, required bool? seekingWork, required int? minimumRating, required int? limit});
  Stream<Either<ProfileValueFailure, EventMerchantVendorProfile>> watchEventMerchProfile({required String profileId});
  Stream<Either<ProfileValueFailure, List<EventMerchantVendorProfile>>> watchCurrentUsersMerchVendorList({required String userId});
  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchCurrentPartnersMerchVendors({required String profileId});
  Stream<Either<ProfileValueFailure, List<EventMerchantVendorProfile>>> watchAllEventMerchProfiles({required List<String> profileIds});

}