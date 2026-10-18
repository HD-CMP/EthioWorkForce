import 'package:equatable/equatable.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/registration_request.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class RegistrationSubmitted extends AdminState {
  final RegistrationRequestResponse response;

  const RegistrationSubmitted(this.response);

  @override
  List<Object?> get props => [response];
}

class PendingRequestsLoaded extends AdminState {
  final List<RegistrationRequestResponse> requests;

  const PendingRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class RegistrationApproved extends AdminState {
  final String message;

  const RegistrationApproved(this.message);

  @override
  List<Object?> get props => [message];
}

class RegistrationRejected extends AdminState {
  final String message;

  const RegistrationRejected(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;
  final ApiError? apiError;

  const AdminError(this.message, {this.apiError});

  @override
  List<Object?> get props => [message, apiError];
}
