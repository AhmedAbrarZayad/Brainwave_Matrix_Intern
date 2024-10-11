import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'To Do List'),
    );
  }
}
class MyHomePage extends StatefulWidget{
  final String title;
  const MyHomePage({super.key,required this.title});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class ToDo{
  String title = '';
  String category = '';
  int priority = 0;
  static Map<String, List<ToDo>>  todos2= {};
  ToDo({required this.title, required this.category,required this.priority});
}
class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  late TabController _tabController;
  late Future<void> _loadDataFuture;
  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDataFuture = loadData();
  }
  Future<void> loadData() async {
    List<String> categories = ['All', 'Personal', 'Work', 'Home'];
    for (String category in categories) {
      List<ToDo> value = await LocalStorage.getData(category);
      if (value.isNotEmpty) {
        ToDo.todos2[category] = value;
      }
      /*ToDo.todos2[category] = value;*/
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Personal'),
            Tab(text: 'Work'),
            Tab(text: 'Home'),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _loadDataFuture, // Call loadData
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return TabBarView(
              controller: _tabController,
              children: const [
                Category(category: 'All'),
                Category(category: 'Personal'),
                Category(category: 'Work'),
                Category(category: 'Home'),
              ],
            );
          }
        },
      ),
    );
  }
}
class Category extends StatefulWidget{
  final String category;
  const Category({super.key,required this.category});
  @override
  State<Category> createState() => _CategoryState();
}
class _CategoryState extends State<Category> {
  void addToDo(String title, String category, int priority){
    setState(() {
      if (ToDo.todos2[category] == null) {
        ToDo.todos2[category] = [];
      }
      ToDo.todos2[category]!.add(ToDo(title: title, category: category, priority: priority));
      if(category != 'All'){
        if(ToDo.todos2['All'] == null){
          ToDo.todos2['All'] = [];
        }
        ToDo.todos2['All']!.add(ToDo(title: title, category: category, priority: priority));
      }
    });
  }
  void remove(String category, int index) {
    if (ToDo.todos2[category] != null && index < ToDo.todos2[category]!.length) {
      String title = ToDo.todos2[category]![index].title;
      String cat = ToDo.todos2[category]![index].category;
      ToDo.todos2[category]!.removeAt(index);
      if(category != "All"){
        if(ToDo.todos2['All'] != null){
          for(int i = 0; i < ToDo.todos2['All']!.length; i++){
            if(ToDo.todos2['All']![i].title == title && ToDo.todos2['All']![i].category == cat){
              ToDo.todos2['All']!.removeAt(i);
              break;
            }
          }
        }
      }else{
        for(int i = 0; i<ToDo.todos2[cat]!.length; i++){
          if(ToDo.todos2[cat]![i].title == title){
            ToDo.todos2[cat]!.removeAt(i);
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context){
    ToDo.todos2[widget.category]?.sort((a, b) => a.priority.compareTo(b.priority));
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: ToDo.todos2[widget.category]?.length ?? 0,
        itemBuilder: (context, index){
          return Container(
            padding: const EdgeInsets.all(8),
            child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.black,
                child: ListTile(
                  title: Text(ToDo.todos2[widget.category]![index].title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(ToDo.todos2[widget.category]![index].category, style: const TextStyle(color: Colors.white)),
                  trailing: Text(ToDo.todos2[widget.category]![index].priority.toString(), style: const TextStyle(color: Colors.white)),
                  onLongPress: (){
                    setState(() {
                      showDialog(
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            title: const Text('Delete'),
                            content: Text('Have you done ${ToDo.todos2[widget.category]![index].title}?'),
                            actions: [
                              TextButton(
                                onPressed: (){
                                  setState(() {
                                    LocalStorage.deleteData(widget.category, index, ToDo.todos2[widget.category]![index].category);
                                    remove(widget.category, index);
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Yes'),
                              ),
                              TextButton(
                                onPressed: (){
                                  Navigator.of(context).pop();
                                },
                                child: const Text('No'),
                              ),
                            ],
                          );
                        },
                      );
                    });
                  },
                )
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => AddToDo(onAdd: addToDo,)
              )
          );
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
class AddToDo extends StatefulWidget{
  final Function(String, String, int) onAdd;
  const AddToDo({super.key,required this.onAdd});
  @override
  State<AddToDo> createState() => _AddToDoState();
}
class _AddToDoState extends State<AddToDo>{
  TextEditingController controller = TextEditingController(), controller2 = TextEditingController(), controller3 = TextEditingController();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text ('Add ToDo'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Todo',
                  hintText: 'Enter the Todo',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller2,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Enter the Category (All / Personal / Work / Home)',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller3,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  hintText: 'Enter the Priority (1 - 5)',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () async{
                    String category = controller2.text;
                    int priority = int.parse(controller3.text);
                    if(category != 'All' && category != 'Personal' && category != 'Work' && category != 'Home'){
                      Fluttertoast.showToast(
                        msg: "Category must be All or Personal or Work or Home",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.blue,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      return;
                    }
                    if(priority < 1 || priority > 5){
                      Fluttertoast.showToast(
                        msg: "Priority must be between 1 and 5",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.blue,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      return;
                    }
                    await LocalStorage.saveData(controller2.text, controller.text, controller2.text, controller3.text);
                    widget.onAdd(controller.text, controller2.text, int.parse(controller3.text));
                    Fluttertoast.showToast(
                      msg: "Added",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                    controller.clear();
                    controller2.clear();
                    controller3.clear();
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class LocalStorage {
  static Future<void> saveData(String key, String title, String category, String priority) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todos = prefs.getStringList(key) ?? [];
    todos.add(jsonEncode({'title': title, 'category': category, 'priority': int.parse(priority)}));
    await prefs.setStringList(key, todos);// Debug print
    if(key != 'All'){
      List<String> todos2 = prefs.getStringList("All") ?? [];
      todos2.add(jsonEncode({'title': title, 'category': category, 'priority': int.parse(priority)}));
      await prefs.setStringList("All", todos2);
    }
  }

  static Future<List<ToDo>> getData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todos = prefs.getStringList(key) ?? [];
    List<ToDo> todo3 = [];
    for (String todo in todos) {
      Map<String, dynamic> mp = jsonDecode(todo);
      String title = mp['title'];
      String category = mp['category'];
      int priority = (mp['priority'] is String) ? int.parse(mp['priority']) : mp['priority'];
      ToDo newToDo = ToDo(
        title: title,
        category: category,
        priority: priority,
      );
      todo3.add(newToDo);// Debug print
    }
    return todo3;
  }
  static Future<void> deleteData(String key, int index, String category) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todos = prefs.getStringList(key) ?? [];
    List<String> todos2 = prefs.getStringList(category) ?? [];
    if(key == "All" && key != category){
      print("Category: $todos2");
      print("Todos: $todos");
      for(int i=0;i<todos2.length;i++){
        if(todos2[i] == todos[index]){
          print(1);
          todos2.removeAt(i);
          break;
        }
      }
      await prefs.setStringList(category, todos2);
    }
    todos.removeAt(index);
    await prefs.setStringList(key, todos);
  }
}


