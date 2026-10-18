from typing import List, Dict
from decimal import Decimal
from datetime import date
import csv
import io
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, Border, Side, PatternFill
from loguru import logger

from app.models.payment import PaymentMethod


class PaymentExportService:
    
    @staticmethod
    def export_cbe_bank_format(payroll_items: List[Dict]) -> bytes:
        """
        Commercial Bank of Ethiopia (CBE) Excel Format
        Columns: Account Number, Beneficiary Name, Amount, Reference
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "CBE Payment Transfer"
        
        header_fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=12)
        border = Border(
            left=Side(style='thin'),
            right=Side(style='thin'),
            top=Side(style='thin'),
            bottom=Side(style='thin')
        )
        
        headers = ["S/N", "Account Number", "Beneficiary Name", "Amount (ETB)", "Reference"]
        for col, header in enumerate(headers, start=1):
            cell = ws.cell(row=1, column=col, value=header)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        
        for idx, item in enumerate(payroll_items, start=2):
            ws.cell(row=idx, column=1, value=idx - 1).border = border
            ws.cell(row=idx, column=2, value=item.get('bank_account_number', '')).border = border
            ws.cell(row=idx, column=3, value=item.get('worker_name', '')).border = border
            amount_cell = ws.cell(row=idx, column=4, value=float(item.get('net_salary', 0)))
            amount_cell.number_format = '#,##0.00'
            amount_cell.border = border
            ws.cell(row=idx, column=5, value=f"Salary-{item.get('payroll_code', '')}").border = border
        
        ws.column_dimensions['A'].width = 8
        ws.column_dimensions['B'].width = 20
        ws.column_dimensions['C'].width = 30
        ws.column_dimensions['D'].width = 15
        ws.column_dimensions['E'].width = 25
        
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        
        logger.info(f"CBE format exported for {len(payroll_items)} workers")
        return output.getvalue()
    
    @staticmethod
    def export_dashen_bank_format(payroll_items: List[Dict]) -> bytes:
        """
        Dashen Bank Excel Format
        Columns: Serial, Account No, Full Name, Amount, Remarks
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "Dashen Salary Transfer"
        
        header_fill = PatternFill(start_color="1F4E78", end_color="1F4E78", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=11)
        border = Border(
            left=Side(style='thin'),
            right=Side(style='thin'),
            top=Side(style='thin'),
            bottom=Side(style='thin')
        )
        
        headers = ["Serial No", "Account No", "Full Name", "Amount", "Remarks"]
        for col, header in enumerate(headers, start=1):
            cell = ws.cell(row=1, column=col, value=header)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        
        for idx, item in enumerate(payroll_items, start=2):
            ws.cell(row=idx, column=1, value=idx - 1).border = border
            ws.cell(row=idx, column=2, value=item.get('bank_account_number', '')).border = border
            ws.cell(row=idx, column=3, value=item.get('worker_name', '')).border = border
            amount_cell = ws.cell(row=idx, column=4, value=float(item.get('net_salary', 0)))
            amount_cell.number_format = '#,##0.00'
            amount_cell.border = border
            ws.cell(row=idx, column=5, value=f"Monthly Salary").border = border
        
        ws.column_dimensions['A'].width = 12
        ws.column_dimensions['B'].width = 18
        ws.column_dimensions['C'].width = 35
        ws.column_dimensions['D'].width = 15
        ws.column_dimensions['E'].width = 20
        
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        
        logger.info(f"Dashen Bank format exported for {len(payroll_items)} workers")
        return output.getvalue()
    
    @staticmethod
    def export_awash_bank_format(payroll_items: List[Dict]) -> bytes:
        """
        Awash Bank Excel Format
        Columns: No, Account Number, Name, Amount, Description
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "Awash Payroll"
        
        header_fill = PatternFill(start_color="C55A11", end_color="C55A11", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=11)
        border = Border(
            left=Side(style='thin'),
            right=Side(style='thin'),
            top=Side(style='thin'),
            bottom=Side(style='thin')
        )
        
        headers = ["No.", "Account Number", "Name", "Amount (ETB)", "Description"]
        for col, header in enumerate(headers, start=1):
            cell = ws.cell(row=1, column=col, value=header)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        
        for idx, item in enumerate(payroll_items, start=2):
            ws.cell(row=idx, column=1, value=idx - 1).border = border
            ws.cell(row=idx, column=2, value=item.get('bank_account_number', '')).border = border
            ws.cell(row=idx, column=3, value=item.get('worker_name', '')).border = border
            amount_cell = ws.cell(row=idx, column=4, value=float(item.get('net_salary', 0)))
            amount_cell.number_format = '#,##0.00'
            amount_cell.border = border
            ws.cell(row=idx, column=5, value=f"Payroll Transfer").border = border
        
        ws.column_dimensions['A'].width = 8
        ws.column_dimensions['B'].width = 22
        ws.column_dimensions['C'].width = 32
        ws.column_dimensions['D'].width = 18
        ws.column_dimensions['E'].width = 25
        
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        
        logger.info(f"Awash Bank format exported for {len(payroll_items)} workers")
        return output.getvalue()
    
    @staticmethod
    def export_telebirr_csv(payroll_items: List[Dict]) -> str:
        """
        Telebirr Mobile Money Bulk Payment CSV
        Format: Phone Number, Amount, Reference
        """
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(["Phone Number", "Amount", "Reference", "Name"])
        
        for item in payroll_items:
            phone = item.get('phone_number', '').replace('+251', '0')
            if not phone.startswith('0'):
                phone = f"0{phone}"
            
            writer.writerow([
                phone,
                f"{float(item.get('net_salary', 0)):.2f}",
                f"SAL-{item.get('employee_id', '')}",
                item.get('worker_name', '')
            ])
        
        csv_content = output.getvalue()
        output.close()
        
        logger.info(f"Telebirr CSV exported for {len(payroll_items)} workers")
        return csv_content
    
    @staticmethod
    def export_mpesa_csv(payroll_items: List[Dict]) -> str:
        """
        M-Pesa Bulk Payment CSV
        Format: Phone Number, Amount, Narration
        """
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(["Phone", "Amount", "Narration"])
        
        for item in payroll_items:
            phone = item.get('phone_number', '').replace('+251', '0')
            if not phone.startswith('0'):
                phone = f"0{phone}"
            
            writer.writerow([
                phone,
                f"{float(item.get('net_salary', 0)):.2f}",
                f"Salary Payment - {item.get('worker_name', '')}"
            ])
        
        csv_content = output.getvalue()
        output.close()
        
        logger.info(f"M-Pesa CSV exported for {len(payroll_items)} workers")
        return csv_content
    
    @staticmethod
    def export_cash_payment_sheet(payroll_items: List[Dict], payroll_code: str, period: str) -> bytes:
        """
        Cash Payment Sheet with Signature Lines
        For manual cash distribution with worker acknowledgment
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "Cash Payment Sheet"
        
        ws.merge_cells('A1:F1')
        title_cell = ws['A1']
        title_cell.value = f"CASH PAYMENT SHEET"
        title_cell.font = Font(bold=True, size=16)
        title_cell.alignment = Alignment(horizontal='center', vertical='center')
        
        ws.merge_cells('A2:F2')
        period_cell = ws['A2']
        period_cell.value = f"Payroll Code: {payroll_code} | Period: {period}"
        period_cell.font = Font(size=11)
        period_cell.alignment = Alignment(horizontal='center')
        
        ws.row_dimensions[1].height = 25
        ws.row_dimensions[2].height = 20
        ws.row_dimensions[3].height = 5
        
        header_fill = PatternFill(start_color="4472C4", end_color="4472C4", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=11)
        border = Border(
            left=Side(style='medium'),
            right=Side(style='medium'),
            top=Side(style='medium'),
            bottom=Side(style='medium')
        )
        
        headers = ["S/N", "Employee ID", "Full Name", "Net Amount (ETB)", "Signature", "Date"]
        for col, header in enumerate(headers, start=1):
            cell = ws.cell(row=4, column=col, value=header)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        
        total_amount = Decimal("0")
        
        for idx, item in enumerate(payroll_items, start=5):
            net_salary = Decimal(str(item.get('net_salary', 0)))
            total_amount += net_salary
            
            ws.cell(row=idx, column=1, value=idx - 4).border = border
            ws.cell(row=idx, column=2, value=item.get('employee_id', '')).border = border
            ws.cell(row=idx, column=3, value=item.get('worker_name', '')).border = border
            
            amount_cell = ws.cell(row=idx, column=4, value=float(net_salary))
            amount_cell.number_format = '#,##0.00'
            amount_cell.border = border
            
            ws.cell(row=idx, column=5, value='').border = border
            ws.cell(row=idx, column=6, value='').border = border
            
            ws.row_dimensions[idx].height = 25
        
        total_row = len(payroll_items) + 5
        ws.merge_cells(f'A{total_row}:C{total_row}')
        total_label = ws.cell(row=total_row, column=1, value="TOTAL")
        total_label.font = Font(bold=True, size=12)
        total_label.alignment = Alignment(horizontal='right')
        total_label.border = border
        
        total_value = ws.cell(row=total_row, column=4, value=float(total_amount))
        total_value.number_format = '#,##0.00'
        total_value.font = Font(bold=True, size=12)
        total_value.border = border
        
        ws.column_dimensions['A'].width = 8
        ws.column_dimensions['B'].width = 15
        ws.column_dimensions['C'].width = 35
        ws.column_dimensions['D'].width = 18
        ws.column_dimensions['E'].width = 25
        ws.column_dimensions['F'].width = 15
        
        signature_row = total_row + 3
        ws.cell(row=signature_row, column=1, value="Prepared By: ___________________")
        ws.cell(row=signature_row, column=4, value="Approved By: ___________________")
        
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        
        logger.info(f"Cash payment sheet exported for {len(payroll_items)} workers")
        return output.getvalue()

    @staticmethod
    def export_erca_tax_schedule_excel(
        payroll_code: str,
        period_str: str,
        payroll_items: List[Dict],
        org_name: str = "EthioWorkforce Enterprise",
        tin_number: str = ""
    ) -> bytes:
        """
        Ethiopian Ministry of Revenues / ERCA Income Tax Schedule & Statutory Remittance
        Excel format required for tax declaration, internal auditing, and statutory filing.
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "ERCA Tax Schedule"

        ws.merge_cells('A1:K1')
        title_cell = ws['A1']
        title_cell.value = "MINISTRY OF REVENUES (ERCA) - EMPLOYMENT INCOME TAX SCHEDULE"
        title_cell.font = Font(bold=True, color="FFFFFF", size=13)
        title_cell.alignment = Alignment(horizontal='center', vertical='center')
        title_cell.fill = PatternFill(start_color="1E4620", end_color="1E4620", fill_type="solid")
        ws.row_dimensions[1].height = 28

        ws['A3'] = "Organization:"
        ws['B3'] = org_name
        ws['A4'] = "TIN Number:"
        ws['B4'] = tin_number or "N/A"
        ws['E3'] = "Payroll Code:"
        ws['F3'] = payroll_code
        ws['E4'] = "Tax Period:"
        ws['F4'] = period_str

        for r in (3, 4):
            ws.cell(row=r, column=1).font = Font(bold=True)
            ws.cell(row=r, column=5).font = Font(bold=True)

        header_fill = PatternFill(start_color="2E7D32", end_color="2E7D32", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=10)
        border = Border(
            left=Side(style='thin'),
            right=Side(style='thin'),
            top=Side(style='thin'),
            bottom=Side(style='thin')
        )

        headers = [
            "S/N", "Employee ID", "Full Name", "TIN / Nat. ID",
            "Gross Pay (ETB)", "Emp. Pension 7%", "Taxable Income",
            "Tax Bracket", "Income Tax (ETB)", "Empr. Pension 11%", "Total Remittance"
        ]
        header_row = 6
        for col, h in enumerate(headers, start=1):
            cell = ws.cell(row=header_row, column=col, value=h)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
            cell.border = border
        ws.row_dimensions[header_row].height = 28

        total_gross = Decimal("0")
        total_emp_pension = Decimal("0")
        total_taxable = Decimal("0")
        total_income_tax = Decimal("0")
        total_empr_pension = Decimal("0")
        total_remittance = Decimal("0")

        for idx, item in enumerate(payroll_items, start=header_row + 1):
            gross = Decimal(str(item.get('gross_salary', 0)))
            emp_pen = Decimal(str(item.get('employee_pension', 0)))
            taxable = gross - emp_pen if gross >= emp_pen else Decimal("0")
            tax = Decimal(str(item.get('income_tax', 0)))
            empr_pen = Decimal(str(item.get('employer_pension', 0)))
            remit = tax + emp_pen + empr_pen

            total_gross += gross
            total_emp_pension += emp_pen
            total_taxable += taxable
            total_income_tax += tax
            total_empr_pension += empr_pen
            total_remittance += remit

            ws.cell(row=idx, column=1, value=idx - header_row).border = border
            ws.cell(row=idx, column=2, value=item.get('employee_id', '')).border = border
            ws.cell(row=idx, column=3, value=item.get('worker_name', '')).border = border
            ws.cell(row=idx, column=4, value=item.get('national_id', '')).border = border

            def _money(c, val):
                cell = ws.cell(row=idx, column=c, value=float(val))
                cell.number_format = '#,##0.00'
                cell.border = border
                return cell

            _money(5, gross)
            _money(6, emp_pen)
            _money(7, taxable)

            tax_rule = item.get('tax_rule_applied', 'standard')
            ws.cell(row=idx, column=8, value=tax_rule).border = border

            _money(9, tax)
            _money(10, empr_pen)
            _money(11, remit)
            ws.row_dimensions[idx].height = 20

        tot_r = len(payroll_items) + header_row + 1
        ws.merge_cells(f'A{tot_r}:D{tot_r}')
        tot_lbl = ws.cell(row=tot_r, column=1, value="TOTAL STATUTORY REMITTANCE")
        tot_lbl.font = Font(bold=True, size=11)
        tot_lbl.alignment = Alignment(horizontal='right')
        tot_lbl.border = border

        for c, val in [
            (5, total_gross), (6, total_emp_pension), (7, total_taxable),
            (9, total_income_tax), (10, total_empr_pension), (11, total_remittance)
        ]:
            cell = ws.cell(row=tot_r, column=c, value=float(val))
            cell.number_format = '#,##0.00'
            cell.font = Font(bold=True)
            cell.border = border

        ws.cell(row=tot_r, column=8, value="").border = border

        widths = {'A': 6, 'B': 14, 'C': 26, 'D': 14, 'E': 16, 'F': 16, 'G': 16, 'H': 14, 'I': 16, 'J': 16, 'K': 18}
        for col_letter, w in widths.items():
            ws.column_dimensions[col_letter].width = w

        sig_r = tot_r + 3
        ws.cell(row=sig_r, column=2, value="Prepared By: ___________________")
        ws.cell(row=sig_r, column=5, value="Verified By: ___________________")
        ws.cell(row=sig_r, column=9, value="Approved By: ___________________")

        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        return output.getvalue()

    @staticmethod
    def export_worker_census_excel(workers_data: List[Dict], site_name: str = "All Sites") -> bytes:
        """
        Enterprise Workforce Census & HR Registry in Excel format.
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "Workforce Census"

        ws.merge_cells('A1:N1')
        title_cell = ws['A1']
        title_cell.value = f"ETHIOWORKFORCE - WORKFORCE CENSUS & HR REGISTER ({site_name.upper()})"
        title_cell.font = Font(bold=True, color="FFFFFF", size=13)
        title_cell.alignment = Alignment(horizontal='center', vertical='center')
        title_cell.fill = PatternFill(start_color="0D47A1", end_color="0D47A1", fill_type="solid")
        ws.row_dimensions[1].height = 28

        ws['A3'] = f"Generated On: {date.today().strftime('%B %d, %Y')} | Total Workers: {len(workers_data)}"
        ws['A3'].font = Font(italic=True)

        header_fill = PatternFill(start_color="1976D2", end_color="1976D2", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=10)
        border = Border(
            left=Side(style='thin'), right=Side(style='thin'),
            top=Side(style='thin'), bottom=Side(style='thin')
        )

        headers = [
            "S/N", "Employee ID", "Full Name", "Phone", "Site", "Workplace",
            "Work Type", "Hierarchy", "Pay Mode", "Base Rate (ETB)", "Bank",
            "Account No.", "Status", "Hire Date"
        ]
        header_row = 5
        for col, h in enumerate(headers, start=1):
            cell = ws.cell(row=header_row, column=col, value=h)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        ws.row_dimensions[header_row].height = 24

        for idx, w in enumerate(workers_data, start=header_row + 1):
            ws.cell(row=idx, column=1, value=idx - header_row).border = border
            ws.cell(row=idx, column=2, value=w.get('employee_id', '')).border = border
            ws.cell(row=idx, column=3, value=w.get('full_name', '')).border = border
            ws.cell(row=idx, column=4, value=w.get('phone_number', '')).border = border
            ws.cell(row=idx, column=5, value=w.get('site_name', '')).border = border
            ws.cell(row=idx, column=6, value=w.get('work_place_name', '')).border = border
            ws.cell(row=idx, column=7, value=w.get('work_type_name', '')).border = border
            ws.cell(row=idx, column=8, value=w.get('hierarchy_level', '')).border = border
            ws.cell(row=idx, column=9, value=w.get('payment_mode', '')).border = border

            rate_cell = ws.cell(row=idx, column=10, value=float(w.get('base_rate', 0) or 0))
            rate_cell.number_format = '#,##0.00'
            rate_cell.border = border

            ws.cell(row=idx, column=11, value=w.get('bank_name', '')).border = border
            ws.cell(row=idx, column=12, value=w.get('bank_account_number', '')).border = border
            ws.cell(row=idx, column=13, value=(w.get('status', '') or '').upper()).border = border
            ws.cell(row=idx, column=14, value=str(w.get('hire_date', ''))).border = border
            ws.row_dimensions[idx].height = 20

        widths = {
            'A': 6, 'B': 14, 'C': 26, 'D': 15, 'E': 16, 'F': 16, 'G': 18,
            'H': 10, 'I': 14, 'J': 15, 'K': 12, 'L': 18, 'M': 12, 'N': 13
        }
        for col_letter, w in widths.items():
            ws.column_dimensions[col_letter].width = w

        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        return output.getvalue()

    @staticmethod
    def export_attendance_roster_excel(roster_data: List[Dict], period_str: str) -> bytes:
        """
        Attendance & Overtime Ledger in Excel format.
        """
        wb = Workbook()
        ws = wb.active
        ws.title = "Attendance Roster"

        ws.merge_cells('A1:M1')
        title_cell = ws['A1']
        title_cell.value = f"ETHIOWORKFORCE - ATTENDANCE & OVERTIME AUDIT LEDGER ({period_str})"
        title_cell.font = Font(bold=True, color="FFFFFF", size=13)
        title_cell.alignment = Alignment(horizontal='center', vertical='center')
        title_cell.fill = PatternFill(start_color="37474F", end_color="37474F", fill_type="solid")
        ws.row_dimensions[1].height = 28

        header_fill = PatternFill(start_color="546E7A", end_color="546E7A", fill_type="solid")
        header_font = Font(bold=True, color="FFFFFF", size=10)
        border = Border(
            left=Side(style='thin'), right=Side(style='thin'),
            top=Side(style='thin'), bottom=Side(style='thin')
        )

        headers = [
            "S/N", "Employee ID", "Full Name", "Site", "Present", "Late",
            "Half Day", "Leave", "Absent", "Days Worked", "Regular Hrs", "OT Hours", "OT Pay (ETB)"
        ]
        header_row = 4
        for col, h in enumerate(headers, start=1):
            cell = ws.cell(row=header_row, column=col, value=h)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
            cell.border = border
        ws.row_dimensions[header_row].height = 24

        tot_present = 0
        tot_worked = 0.0
        tot_ot_hours = 0.0
        tot_ot_pay = Decimal("0")

        for idx, r in enumerate(roster_data, start=header_row + 1):
            worked = float(r.get('days_worked', 0))
            ot_h = float(r.get('overtime_hours', 0))
            ot_p = Decimal(str(r.get('overtime_pay', 0)))

            tot_present += int(r.get('present_count', 0))
            tot_worked += worked
            tot_ot_hours += ot_h
            tot_ot_pay += ot_p

            ws.cell(row=idx, column=1, value=idx - header_row).border = border
            ws.cell(row=idx, column=2, value=r.get('employee_id', '')).border = border
            ws.cell(row=idx, column=3, value=r.get('worker_name', '')).border = border
            ws.cell(row=idx, column=4, value=r.get('site_name', '')).border = border
            ws.cell(row=idx, column=5, value=r.get('present_count', 0)).border = border
            ws.cell(row=idx, column=6, value=r.get('late_count', 0)).border = border
            ws.cell(row=idx, column=7, value=r.get('half_day_count', 0)).border = border
            ws.cell(row=idx, column=8, value=r.get('leave_count', 0)).border = border
            ws.cell(row=idx, column=9, value=r.get('absent_count', 0)).border = border
            ws.cell(row=idx, column=10, value=worked).border = border
            ws.cell(row=idx, column=11, value=r.get('regular_hours', 0)).border = border
            ws.cell(row=idx, column=12, value=ot_h).border = border

            ot_pay_cell = ws.cell(row=idx, column=13, value=float(ot_p))
            ot_pay_cell.number_format = '#,##0.00'
            ot_pay_cell.border = border
            ws.row_dimensions[idx].height = 20

        widths = {
            'A': 6, 'B': 14, 'C': 26, 'D': 16, 'E': 10, 'F': 10,
            'G': 10, 'H': 10, 'I': 10, 'J': 12, 'K': 12, 'L': 12, 'M': 16
        }
        for col_letter, w in widths.items():
            ws.column_dimensions[col_letter].width = w

        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        return output.getvalue()

