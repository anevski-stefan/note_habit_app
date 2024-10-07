import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class HabitList extends StatefulWidget {
  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  List<Map<String, dynamic>> _habits = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshHabits();
  }

  void _refreshHabits() async {
    final habits = await DatabaseHelper.instance.getHabits();
    setState(() {
      _habits = habits;
    });
  }

  void _addHabit() {
    String frequency = 'Everyday';
    String habitName = '';
    List<bool> selectedDays = List.filled(7, true);
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Your First Habit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Container(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text('Create a habit that you can easily complete daily',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                    SizedBox(height: 20),
                    TextField(
                      onChanged: (value) => habitName = value,
                      decoration: InputDecoration(
                        hintText: "Avoid all alcohol on weekends",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Frequency',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: frequency,
                          items: ['Everyday', 'Weekdays', 'Weekends', 'Custom']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              frequency = newValue!;
                              if (frequency == 'Weekdays') {
                                selectedDays = [
                                  true,
                                  true,
                                  true,
                                  true,
                                  true,
                                  false,
                                  false
                                ];
                              } else if (frequency == 'Weekends') {
                                selectedDays = [
                                  false,
                                  false,
                                  false,
                                  false,
                                  false,
                                  true,
                                  true
                                ];
                              } else if (frequency == 'Everyday') {
                                selectedDays = List.filled(7, true);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (frequency == 'Custom')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text('Select Days',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (int i = 0; i < 7; i++)
                                FilterChip(
                                  label: Text(DateFormat('E')
                                      .format(DateTime(2023, 1, 2 + i))),
                                  selected: selectedDays[i],
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedDays[i] = selected;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 20),
                    Text('Start Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null && picked != startDate) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(startDate == null
                                ? 'Select start date'
                                : DateFormat('MMM d, y').format(startDate!)),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (habitName.isNotEmpty) {
                      await DatabaseHelper.instance.insertHabit({
                        'title': habitName,
                        'frequency': frequency,
                        'selectedDays': selectedDays.join(','),
                        'startDate': startDate.toIso8601String(),
                      });
                      Navigator.of(context).pop();
                      _refreshHabits();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habit List'),
        elevation: 0,
      ),
      body: _habits.isEmpty
          ? Center(
              child: Text('No habits yet. Tap + to add a new habit.',
                  style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(habit['title'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Frequency: ${habit['frequency']}'),
                        if (habit['startDate'] != null)
                          Text(
                              'Start Date: ${DateFormat('MMM d, y').format(DateTime.parse(habit['startDate']))}'),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        tooltip: 'Add Habit',
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
