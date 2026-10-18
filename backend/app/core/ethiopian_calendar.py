from datetime import date, datetime, timedelta
from typing import Tuple


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
    def _gregorian_to_jdn(year: int, month: int, day: int) -> int:
        """Convert Gregorian date to Julian Day Number"""
        a = (14 - month) // 12
        y = year + 4800 - a
        m = month + 12 * a - 3
        jdn = day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
        return jdn

    @staticmethod
    def _jdn_to_gregorian(jdn: int) -> Tuple[int, int, int]:
        """Convert Julian Day Number to Gregorian date"""
        a = jdn + 32044
        b = (4 * a + 3) // 146097
        c = a - (146097 * b) // 4
        d = (4 * c + 3) // 1461
        e = c - (1461 * d) // 4
        m = (5 * e + 2) // 153
        day = e - (153 * m + 2) // 5 + 1
        month = m + 3 - 12 * (m // 10)
        year = 100 * b + d - 4800 + m // 10
        return (year, month, day)

    @staticmethod
    def _ethiopian_to_jdn(year: int, month: int, day: int) -> int:
        """Convert Ethiopian date to Julian Day Number
        Ethiopian calendar epoch: JDN 1724220 (Gregorian: August 29, 8 CE)
        """
        epoch = 1724220
        jdn = (
            epoch +
            365 * (year - 1) +
            (year // 4) +
            30 * (month - 1) +
            day - 1
        )
        return jdn

    @staticmethod
    def _jdn_to_ethiopian(jdn: int) -> Tuple[int, int, int]:
        """Convert Julian Day Number to Ethiopian date"""
        epoch = 1724220
        r = (jdn - epoch) % 1461
        n = (r % 365) + 365 * (r // 1460)
        year = 4 * ((jdn - epoch) // 1461) + (r // 365) - (r // 1460) + 1
        month = (n // 30) + 1
        day = (n % 30) + 1
        return (year, month, day)

    @staticmethod
    def gregorian_to_ethiopian(greg_date: date) -> Tuple[int, int, int]:
        jdn = EthiopianCalendar._gregorian_to_jdn(
            greg_date.year, greg_date.month, greg_date.day
        )
        return EthiopianCalendar._jdn_to_ethiopian(jdn)

    @staticmethod
    def ethiopian_to_gregorian(year: int, month: int, day: int) -> date:
        jdn = EthiopianCalendar._ethiopian_to_jdn(year, month, day)
        greg_tuple = EthiopianCalendar._jdn_to_gregorian(jdn)
        return date(greg_tuple[0], greg_tuple[1], greg_tuple[2])

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
