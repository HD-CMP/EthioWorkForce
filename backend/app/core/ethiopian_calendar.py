from datetime import date, datetime, timedelta
from typing import Tuple
import convertdate


class EthiopianCalendar:
    
    ETHIOPIAN_MONTHS = [
        "Meskerem", "Tikimt", "Hidar", "Tahsas", "Tir", "Yekatit",
        "Megabit", "Miazia", "Ginbot", "Sene", "Hamle", "Nehase", "Pagumen"
    ]
    
    ETHIOPIAN_MONTHS_AM = [
        "መስከረም", "ጥቅምት", "ኅዳር", "ታኅሣሥ", "ጥር", "የካቲት",
        "መጋቢት", "ሚያዝያ", "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜን"
    ]

    @staticmethod
    def gregorian_to_ethiopian(greg_date: date) -> Tuple[int, int, int]:
        eth_date = convertdate.ethiopian.from_gregorian(
            greg_date.year, greg_date.month, greg_date.day
        )
        return eth_date

    @staticmethod
    def ethiopian_to_gregorian(year: int, month: int, day: int) -> date:
        greg_date = convertdate.ethiopian.to_gregorian(year, month, day)
        return date(greg_date[0], greg_date[1], greg_date[2])

    @staticmethod
    def format_ethiopian_date(year: int, month: int, day: int, language: str = "en") -> str:
        if language == "am":
            month_name = EthiopianCalendar.ETHIOPIAN_MONTHS_AM[month - 1]
        else:
            month_name = EthiopianCalendar.ETHIOPIAN_MONTHS[month - 1]
        
        return f"{month_name} {day}, {year}"

    @staticmethod
    def get_current_ethiopian_date() -> Tuple[int, int, int]:
        today = date.today()
        return EthiopianCalendar.gregorian_to_ethiopian(today)

    @staticmethod
    def get_ethiopian_month_name(month: int, language: str = "en") -> str:
        if language == "am":
            return EthiopianCalendar.ETHIOPIAN_MONTHS_AM[month - 1]
        return EthiopianCalendar.ETHIOPIAN_MONTHS[month - 1]

    @staticmethod
    def get_ethiopian_fiscal_year(greg_date: date) -> int:
        eth_year, eth_month, _ = EthiopianCalendar.gregorian_to_ethiopian(greg_date)
        if eth_month >= 11:
            return eth_year + 1
        return eth_year
