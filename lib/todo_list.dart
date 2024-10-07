import 'package:flutter/material.dart';
import 'database_helper.dart';

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<Map<String, dynamic>> _todos = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  void _refreshTodos() async {
    final todos = await DatabaseHelper.instance.queryAllTodos();
    setState(() {
      _todos = todos;
    });
  }

  void _addTodo() async {
    if (_controller.text.isNotEmpty) {
      await DatabaseHelper.instance.insertTodo({
        DatabaseHelper.columnTitle: _controller.text,
        DatabaseHelper.columnIsDone: 0,
      });
      _controller.clear();
      _refreshTodos();
    }
  }

  void _toggleTodo(int id, bool isDone) async {
    await DatabaseHelper.instance.updateTodo({
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnIsDone: isDone ? 1 : 0,
    });
    _refreshTodos();
  }

  void _deleteTodo(int id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    _refreshTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter a todo',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  title: Text(todo[DatabaseHelper.columnTitle]),
                  leading: Checkbox(
                    value: todo[DatabaseHelper.columnIsDone] == 1,
                    onChanged: (bool? value) {
                      _toggleTodo(todo[DatabaseHelper.columnId], value!);
                    },
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTodo(todo[DatabaseHelper.columnId]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
