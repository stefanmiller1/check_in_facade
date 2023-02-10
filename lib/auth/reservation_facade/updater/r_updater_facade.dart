part of check_in_facade;

abstract class RUpdaterFacade {

  /// create reservation for listing
  Future<Either<ReservationFormFailure, Unit>> createReservationForm({
    required ReservationItem reservationForm,
    required String paymentIntentId
});

  /// update/edit reservation
  Future<Either<ReservationFormFailure, Unit>> updateReservationFormRequest({
    required ReservationItem reservationForm,
});


  /// delete reservation
  Future<Either<ReservationFormFailure, Unit>> cancelReservationForm({
  required ReservationCancelRequest cancelRequest,
  required ReservationItem reservationForm,
});

}