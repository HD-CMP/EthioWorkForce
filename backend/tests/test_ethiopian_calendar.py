import pytest
from datetime import date
from app.core.ethiopian_calendar import EthiopianCalendar


class TestEthiopianCalendar:
    def test_gregorian_to_ethiopian_conversion(self):
        greg_date = date(2026, 1, 22)
        eth_date = EthiopianCalendar.gregorian_to_ethiopian(greg_date)
        
        assert len(eth_date) == 3
        assert isinstance(eth_date[0], int)
        assert isinstance(eth_date[1], int)
        assert isinstance(eth_date[2], int)
    
    def test_ethiopian_to_gregorian_conversion(self):
        greg_date = EthiopianCalendar.ethiopian_to_gregorian(2018, 5, 15)
        
        assert isinstance(greg_date, date)
    
    def test_format_ethiopian_date_english(self):
        formatted = EthiopianCalendar.format_ethiopian_date(2018, 5, 15, language="en")
        
        assert "Tir" in formatted or "2018" in formatted
    
    def test_format_ethiopian_date_amharic(self):
        formatted = EthiopianCalendar.format_ethiopian_date(2018, 5, 15, language="am")
        
        assert "2018" in formatted
    
    def test_get_current_ethiopian_date(self):
        current_eth_date = EthiopianCalendar.get_current_ethiopian_date()
        
        assert len(current_eth_date) == 3
        assert current_eth_date[0] > 2000
    
    def test_get_ethiopian_month_name(self):
        month_name = EthiopianCalendar.get_ethiopian_month_name(1, language="en")
        assert month_name == "Meskerem"
        
        month_name_am = EthiopianCalendar.get_ethiopian_month_name(1, language="am")
        assert month_name_am == "መስከረም"
