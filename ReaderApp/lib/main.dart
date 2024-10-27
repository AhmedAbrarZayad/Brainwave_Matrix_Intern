import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:toastification/toastification.dart';
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
      home: const MyHomePage(title: 'Reader App'),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  late TabController tabController;

  @override
  void initState(){
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }
  @override
  void dispose(){
    tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Politics'),
            Tab(text: 'Business'),
            Tab(text: 'Technology'),
            Tab(text: 'Science'),
          ],
        ),
        backgroundColor: Colors.red,
      ),
      body: TabBarView(
          controller: tabController,
          children: const [
            Newspage(title: 'Politics'),
            Newspage(title: 'Business'),
            Newspage(title: 'Technology'),
            Newspage(title: 'Science'),
          ],
      ),
    );
  }
}
class News{
  final String title;
  final String description;
  final String url;
  News({required this.title, required this.description, required this.url});
  static Map<String, List<News>> news = {};
  static Map<String, dynamic> fromJson(dynamic json){
    return {
      'title': json['webTitle'],
      'description': json['webTitle'],
      'url': json['webUrl'],
    };
  }
}
class Newspage extends StatefulWidget{
  final dynamic title;
  final String apiKey = "e444f850-85e8-4e6a-95c9-54b178260546";
  const Newspage({super.key, required this.title});

  @override
  State<Newspage> createState() => _NewspageState();
}

class _NewspageState extends State<Newspage>{
  Future getNews() async{
    DateTime now = DateTime.now();
    String url = "https://content.guardianapis.com/search?";
    var response = await http.get(Uri.parse(url+'from-date='+now.year.toString()+'-'+now.month.toString()+'-'+now.day.toString()+'&'+'q='+widget.title+'&api-key='+widget.apiKey));
    if (response.statusCode == 200){
      var jsonData = jsonDecode(response.body);
      return jsonData['response']['results'];
    }else{
      if(mounted){
        toastification.show(
            context: context,
            title: const Text('Error getting the news please restart the app'),
            autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  void initState(){
    super.initState();
    getNews();
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: FutureBuilder(
          future: getNews(),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }else if(snapshot.hasError){
              return const Text("Error has occured");
            }else if(snapshot.hasData){
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index){
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                      color: Colors.black,

                      child: ListTile(
                        title: Text(snapshot.data[index]['webTitle'], style: const TextStyle(color: Colors.white)),
                        onTap: (){
                          print(snapshot.data[index]['webUrl']);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (context) => NewsDetails(url: snapshot.data[index]['webUrl']),
                            ),
                          );
                        },
                      ),
                    )
                  );
                },
              );
            }else{
              return const Text("No Data Available");
            }
          },
        )
      )
    );
  }
}

class NewsDetails extends StatelessWidget{
  final String url;
  const NewsDetails({super.key, required this.url});
  void copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: url)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Text copied to clipboard!")),
      );
    });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                url,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (){
                  copyText(context);
                },
                child: const Text('Copy Text'),
              )
            ],
          )
        ),
      ),
    );
  }
}