import pytest
from decimal import Decimal
from app.services.payroll_calculator import PayrollCalculator, ERCATaxCalculator
from app.models.work_type import PaymentMode, TaxRule


class TestERCATaxCalculator:
    def test_tax_calculation_below_600(self):
        calculator = ERCATaxCalculator()
        tax = calculator.calculate_income_tax(Decimal("500"))
        assert tax == Decimal("0.00")
    
    def test_tax_calculation_bracket_2(self):
        calculator = ERCATaxCalculator()
        tax = calculator.calculate_income_tax(Decimal("1000"))
        assert tax == Decimal("40.00")
    
    def test_tax_calculation_bracket_3(self):
        calculator = ERCATaxCalculator()
        tax = calculator.calculate_income_tax(Decimal("2000"))
        assert tax > Decimal("0")


class TestPayrollCalculator:
    @pytest.fixture
    def calculator(self):
        return PayrollCalculator()
    
    def test_daily_casual_worker_no_tax(self, calculator):
        result = calculator.calculate_worker_payroll(
            base_rate=Decimal("300"),
            payment_mode=PaymentMode.DAILY_RATE,
            tax_rule=TaxRule.DAILY_CASUAL,
            days_worked=20,
            regular_hours=160,
            overtime_hours=0,
            overtime_rate_per_hour=Decimal("56.25"),
            pension_eligible=False,
            employee_pension_rate=0.07,
            employer_pension_rate=0.11,
        )
        
        assert result["gross_salary"] == Decimal("6000")
        assert result["income_tax"] == Decimal("0")
        assert result["employee_pension"] == Decimal("0")
        assert result["net_salary"] == Decimal("6000")
        assert result["tax_rule_applied"] == "daily_casual"
    
    def test_standard_employee_with_tax(self, calculator):
        result = calculator.calculate_worker_payroll(
            base_rate=Decimal("10000"),
            payment_mode=PaymentMode.MONTHLY_SALARY,
            tax_rule=TaxRule.STANDARD_EMPLOYEE,
            days_worked=22,
            regular_hours=176,
            overtime_hours=0,
            overtime_rate_per_hour=Decimal("85.23"),
            pension_eligible=True,
            employee_pension_rate=0.07,
            employer_pension_rate=0.11,
        )
        
        assert result["gross_salary"] == Decimal("10000")
        assert result["income_tax"] > Decimal("0")
        assert result["employee_pension"] == Decimal("700")
        assert result["net_salary"] < result["gross_salary"]
        assert result["tax_rule_applied"] == "standard_employee"
    
    def test_overtime_calculation(self, calculator):
        result = calculator.calculate_worker_payroll(
            base_rate=Decimal("300"),
            payment_mode=PaymentMode.DAILY_RATE,
            tax_rule=TaxRule.DAILY_CASUAL,
            days_worked=20,
            regular_hours=160,
            overtime_hours=10,
            overtime_rate_per_hour=Decimal("56.25"),
            pension_eligible=False,
            employee_pension_rate=0.07,
            employer_pension_rate=0.11,
        )
        
        assert result["overtime_pay"] == Decimal("562.50")
        assert result["gross_salary"] == Decimal("6562.50")
