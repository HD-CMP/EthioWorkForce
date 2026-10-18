import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/registration_request.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRemoteDatasource datasource;

  AdminBloc({required this.datasource}) : super(const AdminInitial()) {
    on<SubmitRegistrationEvent>(_onSubmitRegistration);
    on<FetchPendingRequestsEvent>(_onFetchPendingRequests);
    on<ApproveRegistrationEvent>(_onApproveRegistration);
    on<RejectRegistrationEvent>(_onRejectRegistration);
  }

  Future<void> _onSubmitRegistration(
    SubmitRegistrationEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final response = await datasource.submitRegistrationRequest(event.request);
      emit(RegistrationSubmitted(response));
    } catch (e) {
      if (e is ApiError) {
        emit(AdminError(
          ErrorHandler.getUserFriendlyMessage(e),
          apiError: e,
        ));
      } else {
        emit(AdminError('Failed to submit registration: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchPendingRequests(
    FetchPendingRequestsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final requests = await datasource.getPendingRequests(siteId: event.siteId);
      emit(PendingRequestsLoaded(requests));
    } catch (e) {
      if (e is ApiError) {
        emit(AdminError(
          ErrorHandler.getUserFriendlyMessage(e),
          apiError: e,
        ));
      } else {
        emit(AdminError('Failed to fetch requests: ${e.toString()}'));
      }
    }
  }

  Future<void> _onApproveRegistration(
    ApproveRegistrationEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final approval = RegistrationApproval(
        requestId: event.requestId,
        approved: true,
        approvalNotes: event.approvalNotes,
        siteIds: event.siteIds,
        workPlaceIds: event.workPlaceIds,
      );
      final response = await datasource.approveRequest(approval);
      emit(RegistrationApproved(response['message'] as String));
    } catch (e) {
      if (e is ApiError) {
        emit(AdminError(
          ErrorHandler.getUserFriendlyMessage(e),
          apiError: e,
        ));
      } else {
        emit(AdminError('Failed to approve registration: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRejectRegistration(
    RejectRegistrationEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final approval = RegistrationApproval(
        requestId: event.requestId,
        approved: false,
        approvalNotes: event.rejectionNotes,
      );
      final response = await datasource.approveRequest(approval);
      emit(RegistrationRejected(response['message'] as String));
    } catch (e) {
      if (e is ApiError) {
        emit(AdminError(
          ErrorHandler.getUserFriendlyMessage(e),
          apiError: e,
        ));
      } else {
        emit(AdminError('Failed to reject registration: ${e.toString()}'));
      }
    }
  }
}
