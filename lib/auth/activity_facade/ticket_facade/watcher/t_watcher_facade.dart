part of check_in_facade;

abstract class TWatcherFacade {

  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchAllPurchasedTickets({required String reservationId});
  Stream<Either<AttendeeFormFailure, int>> watchNumberOfTicketsTaken({required String reservationId, required String ticketId});
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchSelectedPurchasedTickets({required String reservationId,  required String ticketId});
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchSelectedOnHoldTickets({required String reservationId,  required String ticketId});
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchCurrentUsersPurchasedTickets({required String currentUser, required String reservationId});

}