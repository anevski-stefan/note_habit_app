import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class HabitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  HabitDetailScreen({required this.habit});

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, bool> _completions = {};
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalCompletions = 0;
  int _totalDays = 0;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadCompletions();
  }

  void _loadCompletions() async {
    final startDate = DateTime.parse(widget.habit['startDate']);
    final endDate = widget.habit['endDate'] != null
        ? DateTime.parse(widget.habit['endDate'])
        : DateTime.now();

    _totalCompletions = 0;

    for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      bool completed = await DatabaseHelper.instance
          .isHabitCompletedOnDate(widget.habit['id'], date);
      setState(() {
        _completions[date] = completed;
        if (completed) _totalCompletions++;
      });
    }

    _calculateStreaks();
  }

  void _calculateStreaks() {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    List<DateTime> sortedDates = _completions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (DateTime date in sortedDates) {
      if (_completions[date] == true) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        if (currentStreak == 0) {
          currentStreak = tempStreak;
        }
        tempStreak = 0;
      }
    }

    setState(() {
      _currentStreak = currentStreak;
      _longestStreak = longestStreak;
    });
  }

  void _toggleCompletion(DateTime date) async {
    if (date.isAfter(DateTime.now())) {
      // Don't allow toggling future dates
      return;
    }

    await DatabaseHelper.instance
        .toggleHabitCompletion(widget.habit['id'], date);

    // If the selected date is in the past, mark all previous days as not done
    if (date.isBefore(DateTime.now())) {
      await DatabaseHelper.instance.markUncheckedDaysAsNotDone(
          habitId: widget.habit['id'], upToDate: date);
    }

    // Reload completions
    _loadCompletions();
  }

  void _editHabit() {
    String newTitle = widget.habit['title'];
    DateTime newStartDate = DateTime.parse(widget.habit['startDate']);
    DateTime? newEndDate = widget.habit['endDate'] != null
        ? DateTime.parse(widget.habit['endDate'])
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Habit Title'),
                  controller: TextEditingController(text: newTitle),
                  onChanged: (value) => newTitle = value,
                ),
                SizedBox(height: 20),
                Text(
                    'Start Date: ${DateFormat('yyyy-MM-dd').format(newStartDate)}'),
                ElevatedButton(
                  child: Text('Change Start Date'),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: newStartDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != newStartDate) {
                      setState(() {
                        newStartDate = picked;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                Text(
                    'Start Date: ${DateFormat('yyyy-MM-dd').format(newStartDate)}'),
                ElevatedButton(
                  child: Text(
                      newEndDate != null ? 'Change End Date' : 'Set End Date'),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: newEndDate ?? DateTime.now(),
                      firstDate: newStartDate,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        newEndDate = picked;
                      });
                    }
                  },
                ),
                if (newEndDate != null)
                  ElevatedButton(
                    child: Text('Remove End Date'),
                    onPressed: () {
                      setState(() {
                        newEndDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                // Update the habit in the database
                await DatabaseHelper.instance.updateHabit({
                  'id': widget.habit['id'],
                  'title': newTitle,
                  'startDate': newStartDate.toIso8601String(),
                  'endDate': newEndDate?.toIso8601String(),
                });

                // Update the widget's habit data
                setState(() {
                  widget.habit['title'] = newTitle;
                  widget.habit['startDate'] = newStartDate.toIso8601String();
                  widget.habit['endDate'] = newEndDate?.toIso8601String();
                });

                // Reload completions and recalculate streaks
                _loadCompletions();

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = DateTime.parse(widget.habit['startDate']);
    final DateTime lastDay = widget.habit['endDate'] != null
        ? DateTime.parse(widget.habit['endDate'])
        : DateTime.now()
            .add(Duration(days: 365)); // Show a year from now if no end date

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Progress', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.habit['title'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              TableCalendar(
                firstDay: startDate,
                lastDay: lastDay,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _toggleCompletion(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  weekendTextStyle: TextStyle(color: Colors.red),
                  holidayTextStyle: TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.black),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day, isSelected: true);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day, isToday: true);
                  },
                ),
                daysOfWeekHeight: 40,
                rowHeight: 60,
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildStreakInfo('This Streak', _currentStreak),
                  _buildStreakInfo('Longest Streak', _longestStreak),
                  _buildStreakInfo(
                    'Completions',
                    _totalCompletions,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _editHabit,
                  child: Text('Edit Habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[100],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day,
      {bool isSelected = false, bool isToday = false}) {
    bool? isCompleted = _completions[day];
    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;
    BoxBorder? border;

    if (isCompleted == true) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (isCompleted == false) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
    }

    if (isSelected) {
      border = Border.all(color: Colors.blue, width: 2);
    } else if (isToday) {
      border = Border.all(color: Colors.blue.withOpacity(0.5), width: 2);
    }

    return Container(
      margin: const EdgeInsets.all(2.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStreakInfo(String title, int value) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center),
          Text('$value',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
