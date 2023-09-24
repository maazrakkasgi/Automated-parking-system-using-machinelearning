import 'dart:convert';

import 'package:aps/models/check_In_Request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
      home: const MyHomePage(title: 'Parking System Using ML'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final myController = TextEditingController();
  final numberController = TextEditingController();
  final List<int> slot = [];
  var greyImage =
      'https://www.vuescript.com/wp-content/uploads/2018/11/Show-Loader-During-Image-Loading-vue-load-image.png';

  var carImage = Image.asset(
    'assets/upload.png',
    height: 300,
    width: 250,
  );
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  void uploadImage() async {
    final ImagePicker picker = ImagePicker();
// Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    final carImageRead = await image!.readAsBytes();
    carImage = Image.memory(carImageRead);
    //carImage = Image.file(image!.path);

    if (image != null) {
      // Create a request
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://127.0.0.1:8000/detect')); // Replace with your API endpoint

      // Attach the image file to the request
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // Send the request and handle the response
      var response = await request.send();
      var resp = await response.stream.bytesToString();
      Map<String, dynamic> user = jsonDecode(resp);
      if (response.statusCode == 200) {
        setState(() {
          greyImage = 'http://127.0.0.1:8000/${user["file_path"]}';
          myController.text = user['number'];
        });
      } else {
        print('Image upload failed with status code ${response.statusCode}');
      }
    }
  }

  Future<void> checkInRequest() async {
    const String apiUrl =
        'http://127.0.0.1:8000/checkinout/'; // Replace with your API URL

    final CheckInRequest checkInData = CheckInRequest(
        myController.text, numberController.text); // Replace with actual data

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(checkInData.toJson()),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['type'] == 'checkIn') {
        slot.add(9);
      } else {
        slot.remove(9);
      }
      setState(() {});

      var snackBar = SnackBar(
        duration: const Duration(seconds: 7),
        content: Text(
            '${jsonDecode(response.body)['type'] == 'checkIn' ? 'Check-in' : 'Check-Out'} successful'),
      );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      // Handle the response as needed
    } else {
      print('Check-in failed with status code: ${response.statusCode}');
      // Handle errors or display an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    height: 500,
                    width: 500,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: uploadImage,
                          child: carImage,
                        ),
                        IconButton(
                            onPressed: uploadImage,
                            icon: const Icon(Icons.upload))
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    height: 400,
                    width: 400,
                    child: Image.network(greyImage),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    height: 300,
                    width: 300,
                    child: SlotTable(
                      slot: slot,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: FormBuilderTextField(
                        name: 'number_plate',
                        decoration:
                            const InputDecoration(labelText: 'Number Plate'),
                        controller: myController,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: FormBuilderTextField(
                        name: 'phone_number',
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        controller: numberController,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: OutlinedButton(
                        onPressed: checkInRequest,
                        style: const ButtonStyle(
                            backgroundColor:
                                MaterialStatePropertyAll(Colors.lightBlue)),
                        child: const Text('Check In/Out'),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SlotTable extends StatefulWidget {
  final List<int> slot;
  const SlotTable({super.key, required this.slot});

  @override
  State<SlotTable> createState() => _SlotTableState();
}

class _SlotTableState extends State<SlotTable> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      // Generate 100 widgets that display their index in the List.
      children: List.generate(9, (index) {
        return Container(
          color: widget.slot.contains(index) ? Colors.green : Colors.white,
          alignment: Alignment.center,
          //decoration: BoxDecoration(border: Border.all()),
          child: Text(
            'A${index + 1}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      }),
    );
  }
}
