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
