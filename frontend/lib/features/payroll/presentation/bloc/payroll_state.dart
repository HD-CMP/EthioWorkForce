import 'package:equatable/equatable.dart';
import '../../domain/entities/payroll.dart';
import '../../domain/entities/payroll_item.dart';

abstract class PayrollState extends Equatable {
  const PayrollState();

  @override
  List<Object?> get props => [];
}

class PayrollInitial extends PayrollState {}

class PayrollLoading extends PayrollState {}

class PayrollLoaded extends PayrollState {
  final List<Payroll> payrolls;
  final double thisMonthTotal;
  final int pendingCount;

  const PayrollLoaded({
    required this.payrolls,
    required this.thisMonthTotal,
    required this.pendingCount,
  });

  @override
  List<Object> get props => [payrolls, thisMonthTotal, pendingCount];
}

class PayrollDetailsLoaded extends PayrollState {
  final Payroll payroll;

  const PayrollDetailsLoaded(this.payroll);

  @override
  List<Object> get props => [payroll];
}

class PayrollError extends PayrollState {
  final String message;

  const PayrollError(this.message);

  @override
  List<Object> get props => [message];
}

class PayrollCalculating extends PayrollState {}

class PayrollCalculated extends PayrollState {
  final Payroll payroll;

  const PayrollCalculated(this.payroll);

  @override
  List<Object> get props => [payroll];
}

class PayrollApproving extends PayrollState {}

class PayrollApproved extends PayrollState {
  final Payroll payroll;

  const PayrollApproved(this.payroll);

  @override
  List<Object> get props => [payroll];
}

class PayrollWithItemsLoaded extends PayrollState {
  final Payroll payroll;
  final List<PayrollItem> items;

  const PayrollWithItemsLoaded(this.payroll, this.items);

  @override
  List<Object> get props => [payroll, items];
}
