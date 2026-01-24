import json
import hashlib
from typing import Dict, List
from datetime import datetime
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
import base64
from loguru import logger


class SneakernetSyncService:
    """
    Enterprise-grade Sneakernet Synchronization Service
    Enables secure offline data exchange via USB/portable media when internet is unavailable
    """
    
    VERSION = "1.0.0"
    
    @staticmethod
    def _generate_encryption_key(password: str, salt: bytes) -> bytes:
        """Generate encryption key from password using PBKDF2"""
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
            backend=default_backend()
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        return key
    
    @staticmethod
    def _calculate_checksum(data: str) -> str:
        """Calculate SHA-256 checksum for data integrity verification"""
        return hashlib.sha256(data.encode()).hexdigest()
    
    def export_sneakernet_package(
        self,
        site_id: int,
        site_code: str,
        workers: List[Dict],
        attendances: List[Dict],
        payrolls: List[Dict],
        encryption_password: str
    ) -> Dict[str, any]:
        """
        Export data package for sneakernet sync
        
        Args:
            site_id: Site identifier
            site_code: Site code
            workers: List of worker records
            attendances: List of attendance records
            payrolls: List of payroll records
            encryption_password: Password for AES-256 encryption
        
        Returns:
            Dict containing encrypted package and metadata
        """
        export_timestamp = datetime.utcnow().isoformat()
        
        payload = {
            "version": self.VERSION,
            "site_id": site_id,
            "site_code": site_code,
            "exported_at": export_timestamp,
            "data": {
                "workers": workers,
                "attendances": attendances,
                "payrolls": payrolls
            },
            "counts": {
                "workers": len(workers),
                "attendances": len(attendances),
                "payrolls": len(payrolls)
            }
        }
        
        payload_json = json.dumps(payload, indent=2)
        checksum = self._calculate_checksum(payload_json)
        
        salt = Fernet.generate_key()[:16]
        encryption_key = self._generate_encryption_key(encryption_password, salt)
        fernet = Fernet(encryption_key)
        
        encrypted_data = fernet.encrypt(payload_json.encode())
        
        package = {
            "package_version": self.VERSION,
            "site_id": site_id,
            "site_code": site_code,
            "exported_at": export_timestamp,
            "checksum": checksum,
            "salt": base64.b64encode(salt).decode(),
            "encrypted_data": base64.b64encode(encrypted_data).decode(),
            "record_counts": payload["counts"]
        }
        
        logger.info(
            f"Sneakernet package exported for site {site_code} "
            f"({len(workers)} workers, {len(attendances)} attendances, {len(payrolls)} payrolls)"
        )
        
        return package
    
    def import_sneakernet_package(
        self,
        package: Dict[str, any],
        encryption_password: str
    ) -> Dict[str, any]:
        """
        Import and decrypt sneakernet package
        
        Args:
            package: Encrypted package dict
            encryption_password: Password for decryption
        
        Returns:
            Decrypted payload data
        
        Raises:
            ValueError: If decryption fails or checksum mismatch
        """
        try:
            if package.get("package_version") != self.VERSION:
                raise ValueError(f"Incompatible package version: {package.get('package_version')}")
            
            salt = base64.b64decode(package["salt"])
            encrypted_data = base64.b64decode(package["encrypted_data"])
            expected_checksum = package["checksum"]
            
            encryption_key = self._generate_encryption_key(encryption_password, salt)
            fernet = Fernet(encryption_key)
            
            decrypted_data = fernet.decrypt(encrypted_data)
            payload_json = decrypted_data.decode()
            
            actual_checksum = self._calculate_checksum(payload_json)
            
            if actual_checksum != expected_checksum:
                raise ValueError("Checksum mismatch - data integrity compromised")
            
            payload = json.loads(payload_json)
            
            logger.info(
                f"Sneakernet package imported for site {package['site_code']} "
                f"(exported at {package['exported_at']})"
            )
            
            return payload
            
        except Exception as e:
            logger.error(f"Failed to import sneakernet package: {e}")
            raise ValueError(f"Import failed: {str(e)}")
    
    def validate_package_integrity(self, package: Dict[str, any]) -> Dict[str, any]:
        """
        Validate package structure and metadata without decryption
        
        Returns:
            Validation report with status and details
        """
        validation_report = {
            "valid": True,
            "errors": [],
            "warnings": []
        }
        
        required_fields = ["package_version", "site_id", "site_code", "exported_at", 
                          "checksum", "salt", "encrypted_data", "record_counts"]
        
        for field in required_fields:
            if field not in package:
                validation_report["valid"] = False
                validation_report["errors"].append(f"Missing required field: {field}")
        
        if package.get("package_version") != self.VERSION:
            validation_report["warnings"].append(
                f"Version mismatch: package v{package.get('package_version')}, current v{self.VERSION}"
            )
        
        try:
            exported_at = datetime.fromisoformat(package.get("exported_at", ""))
            age_days = (datetime.utcnow() - exported_at).days
            
            if age_days > 30:
                validation_report["warnings"].append(
                    f"Package is {age_days} days old - consider data freshness"
                )
        except Exception:
            validation_report["errors"].append("Invalid export timestamp format")
            validation_report["valid"] = False
        
        logger.info(f"Package validation: {'PASSED' if validation_report['valid'] else 'FAILED'}")
        
        return validation_report
    
    def merge_with_conflict_resolution(
        self,
        local_records: List[Dict],
        imported_records: List[Dict],
        strategy: str = "server_wins"
    ) -> Dict[str, any]:
        """
        Merge imported records with local records using conflict resolution
        
        Args:
            local_records: Existing local records
            imported_records: Imported records from sneakernet
            strategy: Conflict resolution strategy
                - "server_wins": Server (imported) data takes precedence
                - "latest_wins": Most recently updated record wins
                - "manual": Flag conflicts for manual resolution
        
        Returns:
            Merge result with resolved records and conflict report
        """
        local_by_id = {record['id']: record for record in local_records}
        
        merged_records = []
        conflicts = []
        new_records = []
        updated_records = []
        
        for imported_record in imported_records:
            record_id = imported_record.get('id')
            
            if record_id not in local_by_id:
                merged_records.append(imported_record)
                new_records.append(record_id)
            else:
                local_record = local_by_id[record_id]
                
                local_updated = local_record.get('updated_at')
                imported_updated = imported_record.get('updated_at')
                
                if local_record == imported_record:
                    merged_records.append(local_record)
                else:
                    if strategy == "server_wins":
                        merged_records.append(imported_record)
                        updated_records.append(record_id)
                    
                    elif strategy == "latest_wins":
                        if imported_updated and local_updated:
                            if imported_updated > local_updated:
                                merged_records.append(imported_record)
                                updated_records.append(record_id)
                            else:
                                merged_records.append(local_record)
                        else:
                            merged_records.append(imported_record)
                            updated_records.append(record_id)
                    
                    elif strategy == "manual":
                        conflicts.append({
                            "record_id": record_id,
                            "local": local_record,
                            "imported": imported_record
                        })
                        merged_records.append(local_record)
        
        for record_id, local_record in local_by_id.items():
            if record_id not in [r['id'] for r in imported_records]:
                merged_records.append(local_record)
        
        merge_result = {
            "total_records": len(merged_records),
            "new_records": len(new_records),
            "updated_records": len(updated_records),
            "conflicts": len(conflicts),
            "conflict_details": conflicts,
            "merged_data": merged_records
        }
        
        logger.info(
            f"Merge completed: {len(new_records)} new, "
            f"{len(updated_records)} updated, {len(conflicts)} conflicts"
        )
        
        return merge_result
