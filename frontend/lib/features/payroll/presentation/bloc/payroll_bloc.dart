import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/payroll.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

@injectable
class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final PayrollRepository repository;

  PayrollBloc({required this.repository}) : super(PayrollInitial()) {
    on<LoadPayrolls>(_onLoadPayrolls);
    on<RefreshPayrolls>(_onRefreshPayrolls);
    on<LoadPayrollDetails>(_onLoadPayrollDetails);
    on<CreateAndCalculatePayroll>(_onCreateAndCalculatePayroll);
    on<CalculatePayroll>(_onCalculatePayroll);
    on<ApprovePayroll>(_onApprovePayroll);
    on<LoadPayrollWithItems>(_onLoadPayrollWithItems);
  }

  Future<void> _onLoadPayrolls(
    LoadPayrolls event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollLoading());
    try {
      final payrolls = await repository.getPayrolls(
        status: event.status,
        siteId: event.siteId,
      );

      final stats = _calculateStatistics(payrolls);

      emit(PayrollLoaded(
        payrolls: payrolls,
        thisMonthTotal: stats['thisMonthTotal']!,
        pendingCount: stats['pendingCount']!.toInt(),
      ));
    } catch (e) {
      emit(PayrollError('Failed to load payrolls: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshPayrolls(
    RefreshPayrolls event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollLoading());
    try {
      final payrolls = await repository.getPayrolls(
        status: event.status,
        siteId: event.siteId,
      );

      final stats = _calculateStatistics(payrolls);

      emit(PayrollLoaded(
        payrolls: payrolls,
        thisMonthTotal: stats['thisMonthTotal']!,
        pendingCount: stats['pendingCount']!.toInt(),
      ));
    } catch (e) {
      emit(PayrollError('Failed to refresh payrolls: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPayrollDetails(
    LoadPayrollDetails event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollLoading());
    try {
      final payroll = await repository.getPayrollById(event.payrollId);
      emit(PayrollDetailsLoaded(payroll));
    } catch (e) {
      emit(PayrollError('Failed to load payroll details: ${e.toString()}'));
    }
  }

  Future<void> _onCreateAndCalculatePayroll(
    CreateAndCalculatePayroll event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollCalculating());
    try {
      final newPayroll = await repository.createPayroll(
        Payroll(
          id: 0,
          payrollCode: '',
          siteId: event.siteId,
          periodType: event.periodType,
          periodStart: event.periodStart,
          periodEnd: event.periodEnd,
          ethiopianMonth: event.ethiopianMonth,
          ethiopianYear: event.ethiopianYear,
          workTypeId: event.workTypeId,
          workPlaceId: event.workPlaceId,
          totalGrossAmount: 0,
          totalDeductions: 0,
          totalNetAmount: 0,
          totalEmployerPension: 0,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final calculatedPayroll = await repository.calculatePayroll(newPayroll.id);
      emit(PayrollCalculated(calculatedPayroll));
    } catch (e) {
      emit(PayrollError('Failed to calculate payroll: ${e.toString()}'));
    }
  }

  Future<void> _onCalculatePayroll(
    CalculatePayroll event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollCalculating());
    try {
      final payroll = await repository.calculatePayroll(event.payrollId);
      emit(PayrollCalculated(payroll));
    } catch (e) {
      emit(PayrollError('Failed to calculate payroll: ${e.toString()}'));
    }
  }

  Future<void> _onApprovePayroll(
    ApprovePayroll event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollApproving());
    try {
      final payroll = await repository.approvePayroll(event.payrollId);
      emit(PayrollApproved(payroll));
    } catch (e) {
      emit(PayrollError('Failed to approve payroll: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPayrollWithItems(
    LoadPayrollWithItems event,
    Emitter<PayrollState> emit,
  ) async {
    emit(PayrollLoading());
    try {
      final payroll = await repository.getPayrollById(event.payrollId);
      final items = await repository.getPayrollItems(event.payrollId);
      emit(PayrollWithItemsLoaded(payroll, items));
    } catch (e) {
      emit(PayrollError('Failed to load payroll details: ${e.toString()}'));
    }
  }

  Map<String, double> _calculateStatistics(List payrolls) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);

    double thisMonthTotal = 0;
    int pendingCount = 0;

    for (var payroll in payrolls) {
      if (payroll.status.toLowerCase() == 'pending' ||
          payroll.status.toLowerCase() == 'calculated') {
        pendingCount++;
      }

      if (payroll.periodStart.isAfter(thisMonthStart) &&
          payroll.periodStart.isBefore(thisMonthEnd)) {
        thisMonthTotal += payroll.totalNetAmount;
      }
    }

    return {
      'thisMonthTotal': thisMonthTotal,
      'pendingCount': pendingCount.toDouble(),
    };
  }
}
