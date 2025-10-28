import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePageTest extends ConsumerStatefulWidget {
  const HomePageTest({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageTestState();
}

class _HomePageTestState extends ConsumerState<HomePageTest> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[300], 
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [        
          _buildChatHeader(),
          _buildChatHistory(),
          _buildTextField(),
          _buildButton(),
          _buildGridView(),
        ],
      ),
    );
  }
  _buildGridView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: 20,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.blue[(index + 1) * 100],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Text(
                  'Item $index',
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  _buildButton() {
    return ElevatedButton(
      onPressed: () {
        // Handle button press
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Colors.blue,
      ),
      child: const Text(
        'Login',
        style: TextStyle(fontSize: 16.0, color: Colors.white),
      ),
    );
  }
  _buildTextField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
  _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Chat App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Handle settings button press
            },
          ),
        ],
      ),
    );
  }
  _buildChatHistory() {
    return SizedBox(
      height: 100, // Fixed height for the horizontal list
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          return CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[(index + 1) * 100],
            child: Text('U$index', style: const TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
//   _buildChatHistory() {
//   return SizedBox(
//     height: 80, // Fixed height for the horizontal list
//     child: ListView.builder(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       itemCount: 10,
//       itemBuilder: (context, index) {
//         return Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.blue[(index + 1) * 100],
//             child: Text('U$index', style: const TextStyle(color: Colors.white)),
//           ),
//         );
//       },
//     ),
//   );
// }
}