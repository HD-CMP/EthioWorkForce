import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/ethiopian_calendar.dart';

Future<DateTime?> showEthiopianDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool showEthiopian = true,
}) async {
  if (!showEthiopian) {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  return await showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _EthiopianDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

enum _DatePickerMode { day, year }
enum _DatePickerEntryMode { calendar, input }

class _EthiopianDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _EthiopianDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_EthiopianDatePickerDialog> createState() => _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<_EthiopianDatePickerDialog> {
  late DateTime _selectedDate;
  late EthiopianDate _currentMonth;
  _DatePickerMode _mode = _DatePickerMode.day;
  _DatePickerEntryMode _entryMode = _DatePickerEntryMode.calendar;
  final TextEditingController _textController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = EthiopianCalendar.fromGregorian(_selectedDate);
    _updateTextController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateTextController() {
    final eth = EthiopianCalendar.fromGregorian(_selectedDate);
    _textController.text = '${eth.month}/${eth.day}/${eth.year}';
  }

  void _toggleEntryMode() {
    setState(() {
      _entryMode = _entryMode == _DatePickerEntryMode.calendar
          ? _DatePickerEntryMode.input
          : _DatePickerEntryMode.calendar;
      if (_entryMode == _DatePickerEntryMode.calendar) {
        _errorText = null;
      }
    });
  }

  void _handleTextInput(String value) {
    setState(() {
      _errorText = null;
      
      final parts = value.split('/');
      if (parts.length != 3) {
        _errorText = 'Invalid format. Use M/D/YYYY';
        return;
      }

      try {
        final month = int.parse(parts[0].trim());
        final day = int.parse(parts[1].trim());
        final year = int.parse(parts[2].trim());

        if (month < 1 || month > 13) {
          _errorText = 'Month must be between 1 and 13';
          return;
        }

        final maxDays = _getDaysInMonth(year, month);
        if (day < 1 || day > maxDays) {
          _errorText = 'Invalid day for this month';
          return;
        }

        final gregorianDate = EthiopianCalendar.toGregorian(year, month, day);
        
        if (gregorianDate.isBefore(widget.firstDate) || gregorianDate.isAfter(widget.lastDate)) {
          _errorText = 'Date out of valid range';
          return;
        }

        _selectedDate = gregorianDate;
        _currentMonth = EthiopianDate(year, month, 1);
      } catch (e) {
        _errorText = 'Invalid date format';
      }
    });
  }

  void _previousMonth() {
    setState(() {
      int newMonth = _currentMonth.month - 1;
      int newYear = _currentMonth.year;
      
      if (newMonth < 1) {
        newMonth = 13;
        newYear--;
      }
      
      _currentMonth = EthiopianDate(newYear, newMonth, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      int newMonth = _currentMonth.month + 1;
      int newYear = _currentMonth.year;
      
      if (newMonth > 13) {
        newMonth = 1;
        newYear++;
      }
      
      _currentMonth = EthiopianDate(newYear, newMonth, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _currentMonth = EthiopianCalendar.fromGregorian(_selectedDate);
    });
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _DatePickerMode.day ? _DatePickerMode.year : _DatePickerMode.day;
    });
  }

  void _selectYear(int year) {
    setState(() {
      _currentMonth = EthiopianDate(year, _currentMonth.month, 1);
      _mode = _DatePickerMode.day;
    });
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 13) {
      return (year % 4 == 3) ? 6 : 5;
    }
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedEthiopian = EthiopianCalendar.fromGregorian(_selectedDate);
    
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 570),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, selectedEthiopian, colorScheme),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _entryMode == _DatePickerEntryMode.input
                    ? _buildInputMode(context, colorScheme)
                    : _mode == _DatePickerMode.day
                        ? _buildDayPicker(context, selectedEthiopian, colorScheme)
                        : _buildYearPicker(context, colorScheme),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EthiopianDate selectedEth, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(_selectedDate);
    
    return Material(
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select date',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: _toggleEntryMode,
                  icon: Icon(
                    _entryMode == _DatePickerEntryMode.calendar
                        ? Icons.keyboard
                        : Icons.calendar_today,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  tooltip: _entryMode == _DatePickerEntryMode.calendar
                      ? 'Switch to input mode'
                      : 'Switch to calendar mode',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_entryMode == _DatePickerEntryMode.calendar) ...[
              InkWell(
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$weekday, ${EthiopianCalendar.monthsEnglish[selectedEth.month - 1]} ${selectedEth.day}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${selectedEth.year}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _mode == _DatePickerMode.day
                            ? Icons.arrow_drop_down
                            : Icons.arrow_drop_up,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                '$weekday, ${EthiopianCalendar.monthsEnglish[selectedEth.month - 1]} ${selectedEth.day}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(BuildContext context, EthiopianDate selectedEth, ColorScheme colorScheme) {
    final daysInMonth = _getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final monthFirstDate = EthiopianCalendar.toGregorian(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final firstWeekday = monthFirstDate.weekday % 7;
    final todayEthiopian = EthiopianCalendar.fromGregorian(DateTime.now());

    return Column(
      key: const ValueKey('day-picker'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                tooltip: 'Previous month',
              ),
              InkWell(
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${EthiopianCalendar.monthsEnglish[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                tooltip: 'Next month',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday) {
                      return const SizedBox.shrink();
                    }

                    final day = index - firstWeekday + 1;
                    final gregorianDate = EthiopianCalendar.toGregorian(
                      _currentMonth.year,
                      _currentMonth.month,
                      day,
                    );

                    final isSelected = selectedEth.year == _currentMonth.year &&
                        selectedEth.month == _currentMonth.month &&
                        selectedEth.day == day;

                    final isToday = todayEthiopian.year == _currentMonth.year &&
                        todayEthiopian.month == _currentMonth.month &&
                        todayEthiopian.day == day;

                    final isDisabled = gregorianDate.isBefore(widget.firstDate) ||
                        gregorianDate.isAfter(widget.lastDate);

                    return InkWell(
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = gregorianDate;
                              });
                            },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : isToday
                                  ? colorScheme.primaryContainer
                                  : null,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: colorScheme.primary, width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : isDisabled
                                      ? colorScheme.onSurface.withOpacity(0.38)
                                      : isToday
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearPicker(BuildContext context, ColorScheme colorScheme) {
    final firstEth = EthiopianCalendar.fromGregorian(widget.firstDate);
    final lastEth = EthiopianCalendar.fromGregorian(widget.lastDate);
    final currentEth = EthiopianCalendar.fromGregorian(DateTime.now());
    
    final years = List.generate(
      lastEth.year - firstEth.year + 1,
      (index) => firstEth.year + index,
    );

    return Column(
      key: const ValueKey('year-picker'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select year',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == _currentMonth.year;
              final isCurrent = year == currentEth.year;
              
              return InkWell(
                onTap: () => _selectYear(year),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isCurrent
                            ? colorScheme.primaryContainer
                            : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected || isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputMode(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      key: const ValueKey('input-mode'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Date',
              hintText: 'M/D/YYYY',
              helperText: 'Ethiopian Calendar (e.g., 5/5/2018)',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            onChanged: _handleTextInput,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ethiopian calendar has 13 months. Months 1-12 have 30 days, month 13 has 5 or 6 days.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final todayGregorian = DateTime.now();
    final todayEthiopian = EthiopianCalendar.fromGregorian(todayGregorian);
    final canSelectToday = !todayGregorian.isBefore(widget.firstDate) &&
        !todayGregorian.isAfter(widget.lastDate);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (canSelectToday && _entryMode == _DatePickerEntryMode.calendar)
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 18),
              label: const Text('Today'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _errorText == null
                ? () {
                    if (_entryMode == _DatePickerEntryMode.input) {
                      _handleTextInput(_textController.text);
                      if (_errorText == null) {
                        Navigator.of(context).pop(_selectedDate);
                      }
                    } else {
                      Navigator.of(context).pop(_selectedDate);
                    }
                  }
                : null,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
