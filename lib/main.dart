import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');
  await Hive.openBox('notes');

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
  late Box box;
  bool isBoxReady = false;

  @override
  void initState() {
    super.initState();
    _loadBox();
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text;
      });
    });
  }

  void _loadBox() async {
    box = Hive.box('database');
    setState(() {
      todolist = box.get('todo') ?? [];
      isBoxReady = true;
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
    if (!isBoxReady) {
      return CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    List<dynamic> filteredList = todolist
        .where((item) =>
        item['task'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    int completedCount =
        todolist.where((item) => item['status'] == true).length;
    int totalCount = todolist.length;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Task',
          style: TextStyle(color: CupertinoColors.systemYellow),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.square_list, color: CupertinoColors.systemYellow),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => NotesPage()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CupertinoSearchTextField(
                controller: searchController,
                placeholder: 'Search ToDo...',
                backgroundColor: CupertinoColors.extraLightBackgroundGray,
              ),
            ),
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
                                  style: TextStyle(color: CupertinoColors.destructiveRed),
                                ),
                                onPressed: () {
                                  setState(() {
                                    todolist.removeWhere((task) => task['task'] == item[index]['task']);
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
                        int originalIndex = todolist.indexWhere((task) => task['task'] == item[index]['task']);
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
                            subtitle: Divider(color: CupertinoColors.systemGrey5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
                                      style: TextStyle(color: CupertinoColors.destructiveRed),
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

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List notes = [];
  List filteredNotes = [];
  late Box noteBox;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteBox = Hive.box('notes');
    notes = noteBox.get('list') ?? [];
    filteredNotes = List.from(notes);
    _searchController.addListener(_filterNotes);
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredNotes = notes.where((note) {
        final text = note['text']?.toLowerCase() ?? '';
        return text.contains(query);
      }).toList();
    });
  }

  void addNote(String text) {
    setState(() {
      final newNote = {"text": text, "createdAt": DateTime.now()};
      notes.insert(0, newNote);
      noteBox.put('list', notes);
      _filterNotes();
    });
  }

  void deleteNote(int indexInFiltered) {
    final noteToDelete = filteredNotes[indexInFiltered];
    setState(() {
      notes.remove(noteToDelete);
      noteBox.put('list', notes);
      _filterNotes();
    });
  }

  void refreshNotes() {
    setState(() {
      notes = noteBox.get('list') ?? [];
      _filterNotes();
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Row(
            children: [
              Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemYellow),
              Text('Todo-List', style: TextStyle(color: CupertinoColors.systemYellow,fontSize: 15)),
              Text("                        "),
              Text('Note', style: TextStyle(color: CupertinoColors.systemYellow, fontSize: 20,fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        middle: Text('All iCloud', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: "Search",
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          color: CupertinoColors.systemRed,
                          child: Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                        ),
                        onDismissed: (_) => deleteNote(index),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => NoteDetailPage(note: note),
                              ),
                            );
                            if (result == true) refreshNotes();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  note['text'] ?? '',
                                  style: TextStyle(fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(note['createdAt']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: Icon(
                CupertinoIcons.square_pencil,
                color: CupertinoColors.systemYellow,
                size: 20,
              ),
              onPressed: () {
                TextEditingController noteController = TextEditingController();
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: Text('New Note'),
                    content: CupertinoTextField(
                      placeholder: 'Type your note here...',
                      controller: noteController,
                      maxLines: null,
                    ),
                    actions: [
                      CupertinoButton(
                        child: Text('Cancel', style: TextStyle(color: CupertinoColors.destructiveRed)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: Text('Save'),
                        onPressed: () {
                          final text = noteController.text.trim();
                          if (text.isNotEmpty) {
                            addNote(text);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
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

class NoteDetailPage extends StatefulWidget {
  final Map note;

  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _controller;
  late Box noteBox;
  late int noteIndex;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note['text']);
    noteBox = Hive.box('notes');

    final allNotes = noteBox.get('list') ?? [];
    noteIndex = allNotes.indexOf(widget.note);
  }

  void saveNote() {
    final updatedText = _controller.text.trim();
    if (updatedText.isEmpty) return;

    final allNotes = noteBox.get('list') ?? [];
    if (noteIndex >= 0 && noteIndex < allNotes.length) {
      allNotes[noteIndex]['text'] = updatedText;
      allNotes[noteIndex]['createdAt'] = DateTime.now();
      noteBox.put('list', allNotes);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Edit Notes',
          style: TextStyle(color: CupertinoColors.systemYellow),
        ),
        previousPageTitle: 'Notes',
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.systemYellow,
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: saveNote,
          child: Icon(
              CupertinoIcons.check_mark, color: CupertinoColors.systemYellow),
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoTextField(
            controller: _controller,
            maxLines: null,
            autofocus: true,
            style: TextStyle(fontSize: 18),
            placeholder: 'Type your note...',
          ),
        ),
      ),
    );
  }
}