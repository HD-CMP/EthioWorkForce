import 'package:equatable/equatable.dart';
import '../../data/models/registration_request.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class SubmitRegistrationEvent extends AdminEvent {
  final RegistrationRequest request;

  const SubmitRegistrationEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class FetchPendingRequestsEvent extends AdminEvent {
  final int? siteId;
  
  const FetchPendingRequestsEvent({this.siteId});
  
  @override
  List<Object?> get props => [siteId];
}

class ApproveRegistrationEvent extends AdminEvent {
  final int requestId;
  final String? approvalNotes;
  final List<int>? siteIds;
  final List<int>? workPlaceIds;

  const ApproveRegistrationEvent({
    required this.requestId,
    this.approvalNotes,
    this.siteIds,
    this.workPlaceIds,
  });

  @override
  List<Object?> get props => [requestId, approvalNotes, siteIds, workPlaceIds];
}

class RejectRegistrationEvent extends AdminEvent {
  final int requestId;
  final String? rejectionNotes;

  const RejectRegistrationEvent({
    required this.requestId,
    this.rejectionNotes,
  });

  @override
  List<Object?> get props => [requestId, rejectionNotes];
}
