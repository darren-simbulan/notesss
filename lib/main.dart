import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  var _ = await Hive.openBox('database');

  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,
    theme: CupertinoThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: CupertinoColors.white,
    ),
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<dynamic> todolist = [];
  TextEditingController addTask = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String _searchQuery = "";

  var box = Hive.box('database');

  @override
  void initState() {
    super.initState();
    todolist = box.get('todo') ?? [];
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text;
      });
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeString = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Today, $timeString';
    } else {
      return '${date.month}/${date.day}, $timeString';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredList = todolist
        .where((item) =>
        item['task'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    int completedCount = todolist.where((item) => item['status'] == true).length;
    int totalCount = todolist.length;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Task',
          style: TextStyle(color: CupertinoColors.systemYellow),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text(
                    'ToDo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 36),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CupertinoSearchTextField(
                controller: searchController,
                placeholder: 'Search ToDo...',
                backgroundColor: CupertinoColors.extraLightBackgroundGray,
              ),
            ),

            // To-Do List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 8),
                itemCount: filteredList.length,
                itemBuilder: (context, int index) {
                  final item = filteredList;
                  final isDone = item[index]['status'];
                  return GestureDetector(
                    onLongPress: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: Text('Delete'),
                            content: Text('Remove ${item[index]['task']}?'),
                            actions: [
                              CupertinoButton(
                                child: Text(
                                  'Yes',
                                  style: TextStyle(
                                      color: CupertinoColors.destructiveRed),
                                ),
                                onPressed: () {
                                  setState(() {
                                    todolist.removeWhere((task) =>
                                    task['task'] == item[index]['task']);
                                    box.put('todo', todolist);
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoButton(
                                child: Text('No'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                    onTap: () {
                      setState(() {
                        item[index]['status'] = !item[index]['status'];
                        item[index]['lastUpdated'] = DateTime.now();
                        int originalIndex = todolist.indexWhere((task) =>
                        task['task'] == item[index]['task']);
                        if (originalIndex != -1) {
                          todolist[originalIndex]['status'] = item[index]['status'];
                          todolist[originalIndex]['lastUpdated'] = item[index]['lastUpdated'];
                          box.put('todo', todolist);
                        }
                      });
                    },
                    child: Container(
                      color: CupertinoColors.white,
                      child: Column(
                        children: [
                          CupertinoListTile(
                            backgroundColor: CupertinoColors.white,
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item[index]['task'],
                                        style: TextStyle(
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          isDone ? 'Done' : 'Pending',
                                          style: TextStyle(
                                            color: isDone
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.destructiveRed,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          CupertinoIcons.circle_fill,
                                          size: 15,
                                          color: isDone
                                              ? CupertinoColors.systemGreen
                                              : CupertinoColors.destructiveRed,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatDateTime(item[index]['createdAt'] ?? DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Divider(
                              color: CupertinoColors.systemGrey5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom bar
            Container(
              color: CupertinoColors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('                '),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('$totalCount ToDo'),
                          SizedBox(height: 4),
                          Text(
                            '$completedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        child: Icon(
                          CupertinoIcons.square_pencil,
                          color: CupertinoColors.systemYellow,
                        ),
                        onPressed: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) {
                              return CupertinoAlertDialog(
                                title: Text('Add Task'),
                                content: CupertinoTextField(
                                  placeholder: 'Add To-Do',
                                  controller: addTask,
                                ),
                                actions: [
                                  CupertinoButton(
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                          color: CupertinoColors.destructiveRed),
                                    ),
                                    onPressed: () {
                                      addTask.text = "";
                                      Navigator.pop(context);
                                    },
                                  ),
                                  CupertinoButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      setState(() {
                                        todolist.add({
                                          "task": addTask.text,
                                          "status": false,
                                          "createdAt": DateTime.now(),
                                          "lastUpdated": DateTime.now(),
                                        });
                                        box.put('todo', todolist);
                                      });
                                      addTask.text = "";
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              );
                            },
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}