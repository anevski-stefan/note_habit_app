import 'package:flutter/material.dart';
import 'package:todo_habit_app/database_helper.dart';
import 'package:todo_habit_app/habit_detail_screen.dart';
import 'package:intl/intl.dart';

class HabitList extends StatefulWidget {
  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  List<Map<String, dynamic>> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() async {
    await DatabaseHelper.instance.markUncheckedDaysAsNotDone();
    List<Map<String, dynamic>> habits =
        await DatabaseHelper.instance.getHabits();
    setState(() {
      _habits = habits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habits'),
      ),
      body: ListView.builder(
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          return _buildHabitTile(_habits[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    return FutureBuilder<int>(
      future: DatabaseHelper.instance.getHabitCompletionCount(
        habit['id'],
        DateTime.parse(habit['startDate']),
        habit['endDate'] != null ? DateTime.parse(habit['endDate']) : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(habit['title']),
            subtitle: Text('Loading...'),
          );
        }

        int completionCount = snapshot.data ?? 0;

        return ListTile(
          title: Text(habit['title']),
          subtitle: Text('Started on: ${_formatDate(habit['startDate'])}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completionCount days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                habit['endDate'] != null
                    ? 'Ends: ${_formatDate(habit['endDate'])}'
                    : 'Ongoing',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HabitDetailScreen(habit: habit),
              ),
            ).then((_) => _loadHabits());
          },
        );
      },
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, y').format(date);
  }

  void _showAddHabitDialog() {
    String title = '';
    String frequency = 'Daily';
    List<String> selectedDays = [];
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    bool isIndefinite = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add New Habit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Habit Title'),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      items: ['Daily', 'Weekly'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          frequency = newValue!;
                          selectedDays = [];
                        });
                      },
                    ),
                    if (frequency == 'Weekly')
                      Wrap(
                        spacing: 5.0,
                        children:
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                .map((day) => FilterChip(
                                      label: Text(day),
                                      selected: selectedDays.contains(day),
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedDays.add(day);
                                          } else {
                                            selectedDays.remove(day);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                      ),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != startDate) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                        ),
                        child: Text(DateFormat('MMM d, y').format(startDate)),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: !isIndefinite,
                          onChanged: (value) {
                            setState(() {
                              isIndefinite = !value!;
                              if (isIndefinite) endDate = null;
                            });
                          },
                        ),
                        Text('Set end date'),
                      ],
                    ),
                    if (!isIndefinite)
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                endDate ?? startDate.add(Duration(days: 30)),
                            firstDate: startDate,
                            lastDate: startDate.add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                          ),
                          child: Text(endDate != null
                              ? DateFormat('MMM d, y').format(endDate!)
                              : 'Select End Date'),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (title.isNotEmpty &&
                        (frequency != 'Weekly' || selectedDays.isNotEmpty)) {
                      _addHabit(
                          title, frequency, selectedDays, startDate, endDate);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addHabit(String title, String frequency, List<String> selectedDays,
      DateTime startDate, DateTime? endDate) async {
    Map<String, dynamic> row = {
      'title': title,
      'frequency': frequency,
      'selectedDays': selectedDays.join(','),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };

    await DatabaseHelper.instance.insertHabit(row);
    _loadHabits();
  }
}
