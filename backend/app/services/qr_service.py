import qrcode
import io
import base64
from typing import Dict
from loguru import logger


class QRCodeService:
    
    @staticmethod
    def generate_worker_qr(worker_id: int, employee_id: str, full_name: str, site_id: int) -> str:
        """
        Generate QR code for worker identification
        Returns base64 encoded PNG image
        
        QR Data Format: WORKER|{worker_id}|{employee_id}|{site_id}
        """
        qr_data = f"WORKER|{worker_id}|{employee_id}|{site_id}"
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        qr_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        qr_url = f"data:image/png;base64,{qr_base64}"
        
        logger.info(f"Generated QR code for worker {employee_id} (ID: {worker_id})")
        return qr_url
    
    @staticmethod
    def parse_worker_qr(qr_data: str) -> Dict[str, any]:
        """
        Parse QR code data to extract worker information
        
        Args:
            qr_data: String in format "WORKER|{worker_id}|{employee_id}|{site_id}"
        
        Returns:
            Dict with worker_id, employee_id, site_id
        
        Raises:
            ValueError if QR data format is invalid
        """
        try:
            parts = qr_data.split('|')
            
            if len(parts) != 4 or parts[0] != "WORKER":
                raise ValueError("Invalid QR code format")
            
            return {
                "worker_id": int(parts[1]),
                "employee_id": parts[2],
                "site_id": int(parts[3])
            }
        except (IndexError, ValueError) as e:
            logger.error(f"Failed to parse QR data: {qr_data} - Error: {e}")
            raise ValueError("Invalid worker QR code")
    
    @staticmethod
    def generate_site_qr(site_id: int, site_code: str, site_name: str) -> str:
        """
        Generate QR code for site identification
        Returns base64 encoded PNG image
        
        QR Data Format: SITE|{site_id}|{site_code}
        """
        qr_data = f"SITE|{site_id}|{site_code}"
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        qr_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        qr_url = f"data:image/png;base64,{qr_base64}"
        
        logger.info(f"Generated QR code for site {site_code} (ID: {site_id})")
        return qr_url
