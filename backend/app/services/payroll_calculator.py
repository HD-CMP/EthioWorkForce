from decimal import Decimal
from typing import Dict, List, Tuple, Optional
from datetime import date
from loguru import logger

from app.models.work_type import TaxRule, PaymentMode
from app.services.payment_period_service import PaymentPeriodService


class ERCATaxCalculator:
    
    TAX_BRACKETS = [
        (Decimal("0"), Decimal("600"), Decimal("0")),
        (Decimal("600"), Decimal("1650"), Decimal("0.10")),
        (Decimal("1650"), Decimal("3200"), Decimal("0.15")),
        (Decimal("3200"), Decimal("5250"), Decimal("0.20")),
        (Decimal("5250"), Decimal("7800"), Decimal("0.25")),
        (Decimal("7800"), Decimal("10900"), Decimal("0.30")),
        (Decimal("10900"), Decimal("999999999"), Decimal("0.35")),
    ]

    @classmethod
    def calculate_income_tax(cls, taxable_income: Decimal) -> Decimal:
        if taxable_income <= 0:
            return Decimal("0")

        tax = Decimal("0")
        remaining_income = taxable_income

        for i, (lower, upper, rate) in enumerate(cls.TAX_BRACKETS):
            if remaining_income <= 0:
                break

            if i == 0:
                taxable_in_bracket = min(remaining_income, upper - lower)
            else:
                taxable_in_bracket = min(remaining_income, upper - lower)

            bracket_tax = taxable_in_bracket * rate
            tax += bracket_tax
            remaining_income -= taxable_in_bracket

            logger.debug(
                f"Bracket {i + 1}: {lower}-{upper} @ {rate * 100}% | "
                f"Taxable: {taxable_in_bracket} | Tax: {bracket_tax}"
            )

        return tax.quantize(Decimal("0.01"))


class PayrollCalculator:
    
    def __init__(self):
        self.tax_calculator = ERCATaxCalculator()

    def calculate_worker_payroll(
        self,
        base_rate: Decimal,
        payment_mode: PaymentMode,
        tax_rule: TaxRule,
        days_worked: int,
        regular_hours: int,
        overtime_hours: float,
        overtime_rate_per_hour: Decimal,
        pension_eligible: bool,
        employee_pension_rate: float,
        employer_pension_rate: float,
        allowances: Decimal = Decimal("0"),
        other_deductions: Decimal = Decimal("0"),
        allocated_overtime_hours: Decimal = Decimal("0"),
        allocated_overtime_rate: Decimal = Decimal("0"),
        period_total_calendar_days: int = 0,  # 6-day work week days in payroll period
    ) -> Dict[str, Decimal]:

        base_salary = self._calculate_base_salary(
            base_rate, payment_mode, days_worked, regular_hours, period_total_calendar_days
        )

        overtime_pay = self._calculate_overtime_pay(
            overtime_hours, overtime_rate_per_hour
        )

        allocated_overtime_pay = self._calculate_allocated_overtime(
            allocated_overtime_hours, allocated_overtime_rate
        )

        gross_salary = base_salary + overtime_pay + allocated_overtime_pay + allowances

        if tax_rule == TaxRule.DAILY_CASUAL:
            return {
                "base_salary": base_salary,
                "overtime_pay": overtime_pay,
                "allocated_overtime_pay": allocated_overtime_pay,
                "allowances": allowances,
                "gross_salary": gross_salary,
                "income_tax": Decimal("0"),
                "employee_pension": Decimal("0"),
                "employer_pension": Decimal("0"),
                "cost_sharing": Decimal("0"),
                "other_deductions": other_deductions,
                "total_deductions": other_deductions,
                "net_salary": gross_salary - other_deductions,
                "tax_rule_applied": "daily_casual",
            }

        income_tax = self.tax_calculator.calculate_income_tax(gross_salary)

        employee_pension = Decimal("0")
        employer_pension = Decimal("0")
        if pension_eligible:
            employee_pension = (gross_salary * Decimal(str(employee_pension_rate))).quantize(
                Decimal("0.01")
            )
            employer_pension = (gross_salary * Decimal(str(employer_pension_rate))).quantize(
                Decimal("0.01")
            )
            # ERCA: Income tax is computed on taxable income = gross - employee pension
            taxable_income = gross_salary - employee_pension
            income_tax = self.tax_calculator.calculate_income_tax(taxable_income)

        cost_sharing = Decimal("0")

        total_deductions = income_tax + employee_pension + cost_sharing + other_deductions
        net_salary = gross_salary - total_deductions

        return {
            "base_salary": base_salary,
            "overtime_pay": overtime_pay,
            "allocated_overtime_pay": allocated_overtime_pay,
            "allowances": allowances,
            "gross_salary": gross_salary,
            "income_tax": income_tax,
            "employee_pension": employee_pension,
            "employer_pension": employer_pension,
            "cost_sharing": cost_sharing,
            "other_deductions": other_deductions,
            "total_deductions": total_deductions,
            "net_salary": net_salary,
            "tax_rule_applied": "standard_employee",
        }

    def _calculate_base_salary(
        self, base_rate: Decimal, payment_mode: PaymentMode, days_worked: int,
        regular_hours: int, total_working_days: int = 0
    ) -> Decimal:
        if payment_mode == PaymentMode.MONTHLY_SALARY:
            # PRORATION: If we know total working days in the period and the
            # worker didn't work all of them, prorate the monthly salary.
            # This handles leave, absent days, and mid-month joiners/leavers.
            if total_working_days > 0 and days_worked < total_working_days:
                daily_rate = base_rate / Decimal(str(total_working_days))
                prorated = (daily_rate * Decimal(str(days_worked))).quantize(Decimal("0.01"))
                logger.debug(
                    f"Monthly proration: {days_worked}/{total_working_days} days "
                    f"@ {base_rate} => {prorated}"
                )
                return prorated
            # Full month — return full salary
            return base_rate

        elif payment_mode == PaymentMode.DAILY_RATE:
            return base_rate * Decimal(str(days_worked))

        elif payment_mode == PaymentMode.HOURLY_RATE:
            return base_rate * Decimal(str(regular_hours))

        elif payment_mode == PaymentMode.PIECE_RATE:
            return base_rate * Decimal(str(days_worked))

        return Decimal("0")

    def _calculate_overtime_pay(
        self,
        overtime_hours: float,
        overtime_rate_per_hour: Decimal,
    ) -> Decimal:
        if overtime_hours == 0 or overtime_rate_per_hour is None or overtime_rate_per_hour == 0:
            return Decimal("0")

        overtime_pay = overtime_rate_per_hour * Decimal(str(overtime_hours))
        return overtime_pay.quantize(Decimal("0.01"))

    def _calculate_allocated_overtime(
        self,
        allocated_hours: Decimal,
        allocated_rate: Decimal,
    ) -> Decimal:
        if allocated_hours == 0 or allocated_rate == 0:
            return Decimal("0")
        
        allocated_pay = allocated_hours * allocated_rate
        return allocated_pay.quantize(Decimal("0.01"))

    def calculate_bulk_payroll(
        self, worker_payroll_data: List[Dict]
    ) -> Tuple[List[Dict], Dict[str, Decimal]]:
        
        payroll_items = []
        totals = {
            "total_gross": Decimal("0"),
            "total_deductions": Decimal("0"),
            "total_net": Decimal("0"),
            "total_employer_pension": Decimal("0"),
        }

        for data in worker_payroll_data:
            worker_id = data.get("worker_id")
            
            payroll_period_start = data.get("payroll_period_start")
            payroll_period_end = data.get("payroll_period_end")
            payment_period_days = data.get("payment_period_days")
            payment_period_start_date = data.get("payment_period_start_date")
            payment_mode = data.get("payment_mode")
            
            # Build kwargs — strip fields that are metadata only (not calculator inputs)
            # NOTE: period_total_calendar_days IS passed through to the calculator for proration
            calc_keys = {
                "payroll_period_start", "payroll_period_end", "payment_period_days",
                "payment_period_start_date", "worker_id"
            }
            calc_data = {k: v for k, v in data.items() if k not in calc_keys}
            
            result = self.calculate_worker_payroll(**calc_data)
            
            result["worker_id"] = worker_id
            result["days_worked"] = data.get("days_worked")
            result["regular_hours"] = data.get("regular_hours")
            result["overtime_hours"] = data.get("overtime_hours")
            
            if payroll_period_start and payroll_period_end:
                period_start, period_end, period_length, is_prorated = PaymentPeriodService.calculate_worker_period(
                    payroll_period_start,
                    payroll_period_end,
                    payment_period_days,
                    payment_period_start_date,
                    payment_mode,
                )
                
                result["payment_period_start"] = period_start
                result["payment_period_end"] = period_end
                result["payment_period_days"] = period_length
                result["is_prorated"] = is_prorated
                result["payment_period_type"] = PaymentPeriodService._get_period_type_name(
                    period_length, payment_mode
                )
            else:
                result["payment_period_start"] = None
                result["payment_period_end"] = None
                result["payment_period_days"] = None
                result["is_prorated"] = False
                result["payment_period_type"] = None
            
            payroll_items.append(result)
            
            totals["total_gross"] += result["gross_salary"]
            totals["total_deductions"] += result["total_deductions"]
            totals["total_net"] += result["net_salary"]
            totals["total_employer_pension"] += result["employer_pension"]

        logger.info(f"Calculated payroll for {len(payroll_items)} workers")
        logger.info(f"Totals: {totals}")

        return payroll_items, totals
