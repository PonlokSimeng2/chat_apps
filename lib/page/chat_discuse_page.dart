import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatDiscusePage extends ConsumerStatefulWidget {
  const ChatDiscusePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatDiscusePageState();
}

class _ChatDiscusePageState extends ConsumerState<ChatDiscusePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.07,),
          _newAppBar(),
          _buildbody()
           
        ],
      ),
    );
  }

 _newAppBar() {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.arrow_back_ios),
            SizedBox(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                      child: Text('',style: const TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10,),
                  SizedBox(
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("data",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        Text("data")
                      ],
                    ),
                  )
                ],
              ),
            ),
          Icon(Icons.camera_alt_outlined),
          ],
        );
  }
  _buildbody() {
  

  }
}