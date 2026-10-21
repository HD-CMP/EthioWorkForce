from datetime import date, timedelta
from typing import Dict, Tuple, Optional
from decimal import Decimal
from loguru import logger

from app.models.work_type import PaymentMode


class PaymentPeriodService:
    """
    Professional payment period alignment service.
    Handles workers with different payment cycles and start dates.
    """
    
    @staticmethod
    def calculate_worker_period(
        payroll_start: date,
        payroll_end: date,
        payment_period_days: Optional[int],
        payment_period_start_date: Optional[date],
        payment_mode: PaymentMode,
    ) -> Tuple[date, date, int, bool]:
        """
        Calculate the actual payment period for a worker within the payroll period.
        
        Returns:
            - period_start: Actual start date for this worker
            - period_end: Actual end date for this worker
            - period_length_days: Number of days in their payment period
            - is_prorated: Whether the payment is prorated (partial period)
        """
        
        # For daily/hourly/piece workers with a configured cycle (e.g. 14 days)
        if payment_mode in [PaymentMode.DAILY_RATE, PaymentMode.HOURLY_RATE, PaymentMode.PIECE_RATE]:
            period_length = payment_period_days if payment_period_days else ((payroll_end - payroll_start).days + 1)
            return payroll_start, payroll_end, period_length, False
        
        # For monthly salary, align to their payment period
        if payment_mode == PaymentMode.MONTHLY_SALARY and payment_period_days:
            return PaymentPeriodService._align_period(
                payroll_start,
                payroll_end,
                payment_period_days,
                payment_period_start_date,
            )
        
        # Default: use payroll period as-is
        period_days = payment_period_days if payment_period_days else ((payroll_end - payroll_start).days + 1)
        return payroll_start, payroll_end, period_days, False
    
    @staticmethod
    def _align_period(
        payroll_start: date,
        payroll_end: date,
        payment_period_days: int,
        payment_period_start_date: Optional[date],
    ) -> Tuple[date, date, int, bool]:
        """
        Align worker's payment period with their configured cycle.
        """
        
        if not payment_period_start_date:
            # No anchor date, use payroll period
            period_days = (payroll_end - payroll_start).days + 1
            return payroll_start, payroll_end, period_days, False
        
        # Find the most recent period start that includes the payroll period
        current_period_start = payment_period_start_date
        
        # Move forward to the period that overlaps with payroll_start
        while current_period_start + timedelta(days=payment_period_days) < payroll_start:
            current_period_start += timedelta(days=payment_period_days)
        
        # Calculate period end
        period_end = current_period_start + timedelta(days=payment_period_days - 1)
        
        # Check if this is a partial period (prorated)
        is_prorated = (current_period_start < payroll_start or period_end > payroll_end)
        
        # Adjust to fit within payroll period
        actual_start = max(current_period_start, payroll_start)
        actual_end = min(period_end, payroll_end)
        
        logger.debug(
            f"Period alignment: "
            f"Config cycle: {payment_period_days} days, "
            f"Anchor: {payment_period_start_date}, "
            f"Calculated: {current_period_start} to {period_end}, "
            f"Adjusted: {actual_start} to {actual_end}, "
            f"Prorated: {is_prorated}"
        )
        
        return actual_start, actual_end, payment_period_days, is_prorated
    
    @staticmethod
    def calculate_proration_factor(
        actual_days_worked: int,
        standard_period_days: int,
    ) -> Decimal:
        """
        Calculate proration factor for partial periods.
        """
        if standard_period_days == 0:
            return Decimal("1")
        
        factor = Decimal(actual_days_worked) / Decimal(standard_period_days)
        return factor.quantize(Decimal("0.0001"))
    
    @staticmethod
    def format_period_description(
        period_start: date,
        period_end: date,
        payment_period_days: int,
        is_prorated: bool,
        payment_mode: PaymentMode,
    ) -> str:
        """
        Generate a human-readable description of the payment period.
        """
        period_type = PaymentPeriodService._get_period_type_name(
            payment_period_days, payment_mode
        )
        
        date_range = f"{period_start.strftime('%b %d')} - {period_end.strftime('%b %d, %Y')}"
        
        if is_prorated:
            return f"{period_type} (Prorated) • {date_range}"
        else:
            return f"{period_type} • {date_range}"
    
    @staticmethod
    def _get_period_type_name(payment_period_days: int, payment_mode: PaymentMode) -> str:
        """
        Get a friendly name for the payment period.
        """
        if payment_period_days == 14 or (payment_mode == PaymentMode.DAILY_RATE and payment_period_days == 14):
            return "14-Day (Bi-Weekly)"
        elif payment_period_days == 7:
            return "Weekly"
        elif payment_period_days and 28 <= payment_period_days <= 31:
            return "Monthly"
        elif payment_mode == PaymentMode.DAILY_RATE:
            return "Daily"
        elif payment_mode == PaymentMode.HOURLY_RATE:
            return "Hourly"
        elif payment_period_days:
            return f"{payment_period_days}-Day Cycle"
        else:
            return "Standard"
    
    @staticmethod
    def get_period_group_key(
        payment_mode: PaymentMode,
        payment_period_days: Optional[int],
    ) -> str:
        """
        Generate a key for grouping workers by payment period type.
        """
        if payment_mode == PaymentMode.DAILY_RATE:
            return "daily"
        elif payment_mode == PaymentMode.HOURLY_RATE:
            return "hourly"
        elif payment_period_days == 7:
            return "weekly"
        elif payment_period_days == 14:
            return "bi_weekly"
        elif payment_period_days and 28 <= payment_period_days <= 31:
            return "monthly"
        else:
            return f"custom_{payment_period_days or 0}_days"
