part of check_in_facade;

@LazySingleton(as: TWatcherFacade)
class TicketWatcherFacade implements TWatcherFacade {

  final FirebaseFirestore _firestore;

  TicketWatcherFacade(this._firestore);


  @override
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchSelectedPurchasedTickets({required String reservationId,  required String ticketId}) async* {

    try {
      yield* _firestore
          .collection('activity_directory')
          .doc(reservationId)
          .collection('tickets')
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: false).snapshots().map((event) {
              return right<AttendeeFormFailure, List<TicketItem>>(event.docs.map((ticket) => TicketItemDto.fromFireStore(ticket.data()).toDomain()).toList());
      });

      yield left(const AttendeeFormFailure.ticketsNoLongerAvailable());
      } catch (e) {
        yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
      }
    }

  @override
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchSelectedOnHoldTickets({required String reservationId,  required String ticketId}) async* {

    try {

      yield* _firestore
          .collection('activity_directory')
          .doc(reservationId)
          .collection('tickets')
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch).snapshots()
          .map((event) {

          return right<AttendeeFormFailure, List<TicketItem>>(event.docs.map((ticket) => TicketItemDto.fromFireStore(ticket.data()).toDomain()).toList());

      });

      yield left(const AttendeeFormFailure.ticketsNoLongerAvailable());
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }

  }

  @override
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchAllPurchasedTickets({required String reservationId}) async* {
     try {
       yield* _firestore
           .collection('activity_directory')
           .doc(reservationId)
           .collection('tickets')
           .where('isOnHold', isEqualTo: false).snapshots().map((event) {
         if (event.docs.isNotEmpty) {
           return right<AttendeeFormFailure, List<TicketItem>>(event.docs.map((ticket) => TicketItemDto.fromFireStore(ticket.data()).toDomain()).toList());
         }
         return left(const AttendeeFormFailure.attendeeServerError());
       });
     } catch (e) {
       yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }

  @override
  Stream<Either<AttendeeFormFailure, int>> watchNumberOfTicketsTaken({required String reservationId, required String ticketId}) async* {

    final ticketDoc = _firestore.collection('activity_directory').doc(reservationId).collection('tickets');

    try {

      final purchasedTicketsCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: false).count().get();
      final onHoldTicketsCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch).count().get();

      final ticketCount = purchasedTicketsCount.count + onHoldTicketsCount.count;

      yield right(ticketCount);
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Stream<Either<AttendeeFormFailure, List<TicketItem>>> watchCurrentUsersPurchasedTickets({required String currentUser, required String reservationId}) async* {
    try {
      yield* _firestore
          .collection('activity_directory')
          .doc(reservationId)
          .collection('tickets')
          .where('ticketOwner', isEqualTo: currentUser)
          .where('isOnHold', isEqualTo: false).snapshots().map((event) {
        if (event.docs.isNotEmpty) {
          return right<AttendeeFormFailure, List<TicketItem>>(event.docs.map((ticket) => TicketItemDto.fromFireStore(ticket.data()).toDomain()).toList());
        }
        return left(const AttendeeFormFailure.attendeeServerError());
      });
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }
}


class AttendeeAuthCore {

  AttendeeAuthCore._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;
  FirebaseStorage getFirebaseStorage() => FirebaseStorage.instance;
  FirebaseFunctions getFirebaseFunctions() => FirebaseFunctions.instance;
  
  /// Singleton instance.
  static final AttendeeAuthCore instance = AttendeeAuthCore._privateConstructor();


  Future<String> kPassUrl(String ownerId) async {
    final ref = getFirebaseStorage().ref().child('passes/event.pkpass');
    try {
       final url = await ref.getDownloadURL();
       return url;
    } catch (e) {
      return 'failed';
    }
  }

  Future<bool?> generatePKPassForTicket({
    required String description,
    required String ticketHolderName,
    required String ticketDate,
    required String ticketFee,
    required String facilityName,
    required String activityLocation,
    required String ticketId}) async {

    final functionRef = getFirebaseFunctions().httpsCallable('passKitCallable');

    final pkPassItem = PKPassItem(
        qrText: ticketId,
        codeAlt: 'alt',
        header: FieldItem(
          label: "Date",
          value: ticketDate
        ),
        primary: FieldItem(
          label: "Ticket",
          value: facilityName,
        ),
        secondary: [
          FieldItem(label: "Name", value: firebaseUser?.displayName ?? ticketHolderName),
          FieldItem(label: "Cost", value: ticketFee)
        ]
    );

    final pkPassJson = PKPassItemDto.fromDomain(pkPassItem).toJson();
    // print(pkPassJson);

    try {

      final data = {
        "qrText": "0000001",
        "codeAlt": "alt",
        "header": {
          "label": "Date",
          "value": "10/09/2023"
        },
        "primary": {
          "label": "Ticket",
          "value": "Pop-Up Weed Shop"
        },
        "secondary": [
          {
            "label": "Name",
            "value": "Stefan MMMM"
          },
          {
            "label": "Cost",
            "value": "30.00 CAD"
          }
        ]
      };

      // final responseData = await http.post(
      //   Uri.parse('https://us-central1-cico-8298b.cloudfunctions.net/passKit'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: data,
      // );


      final responseData = await functionRef.call(jsonEncode(pkPassJson));

      // final result = jsonDecode(responseData.body);
      // print(result);
      print(responseData.data);
      if (responseData.data == null) {
        return false;
      }

      return true;
    } on FirebaseFunctionsException catch (err) {
      print(err.message);
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }
  
  Stream<int> getTicketCount({
    required ReservationItem reservation,
    required ActivityTicketOption ticket
  }) async* {

    final ticketDoc = getFirebaseFirestore().collection('activity_directory').doc(reservation.reservationId.getOrCrash()).collection('tickets');

    try {

      final purchasedTicketsCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticket.ticketId.getOrCrash())
          .where('isOnHold', isEqualTo: false).count().get();
      final onHoldTicketsCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticket.ticketId.getOrCrash())
          .where('isOnHold', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: DateTime.now().add(const Duration(minutes: 3)).millisecondsSinceEpoch).count().get();

      final ticketCount = purchasedTicketsCount.count + onHoldTicketsCount.count;

      yield  ticketCount;
    } catch (e) {
      yield 0;
    }
  }

}