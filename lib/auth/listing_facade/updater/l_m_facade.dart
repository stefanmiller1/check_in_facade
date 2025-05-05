part of check_in_facade;

abstract class LMFacade {

  Future<Either<ListingFormFailure, Unit>> updateListingForm({
    required ListingManagerForm listingForm
});

 
}