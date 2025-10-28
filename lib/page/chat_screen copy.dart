// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class ChatScreen extends ConsumerStatefulWidget {
//   final String senderId;
//   final String otherUserName;
//   final String otherUserAvatar;
//   final String receiverId;

//   const ChatScreen({
//     super.key,
//     required this.receiverId,
//     required this.senderId,
//     required this.otherUserName,
//     required this.otherUserAvatar,
//   });

//   @override
//   ConsumerState<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends ConsumerState<ChatScreen> {
//   late WebSocketChannel _channel;
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, dynamic>> _messages = [];
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//   }

//   void _connectWebSocket() {
//     _channel = WebSocketChannel.connect(
//       Uri.parse(
//         'wss://desirable-moira-kfa-f246aea1.koyeb.app/ws?userId=${widget.senderId}',
//       ),
//     );

//     // Listen to incoming messages
//     _channel.stream.listen(
//       (message) {
//         final decodedMessage = jsonDecode(message);
//         setState(() {
//           _messages.add(decodedMessage);
//         });
//         _scrollToBottom();
//       },
//       onError: (error) => print('WebSocket error: $error'),
//       onDone: () => print('WebSocket closed'),
//     );
//   }

//   void _sendMessage() {
//     if (_messageController.text.trim().isEmpty) return;

//     final message = {
//       'message': _messageController.text.trim(),
//       'senderId': widget.senderId,
//       'receiverId': widget.receiverId,
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     _channel.sink.add(jsonEncode(message));

//     setState(() {
//       _messages.add(message);
//     });

//     _messageController.clear();
//     _scrollToBottom();
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             Stack(
//               children: [
//                 CircleAvatar(
//                   backgroundImage: NetworkImage(widget.otherUserAvatar),
//                   radius: 20,
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     width: 12,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.black, width: 2),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "${widget.otherUserName}",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Text(
//                   'Online',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.phone, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 final isSentByMe = message['userId'] == widget.senderId;
//                 return _buildMessageBubble(
//                   message['message']?.toString() ?? '',
//                   isSentByMe,
//                   DateTime.parse(message['timestamp']),
//                 );
//               },
//             ),
//           ),
//           _buildMessageInput(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageBubble(String message, bool isSentByMe, DateTime time) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         mainAxisAlignment: isSentByMe
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isSentByMe) ...[
//             CircleAvatar(
//               backgroundImage: NetworkImage(widget.otherUserAvatar),
//               radius: 16,
//             ),
//             const SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isSentByMe ? Colors.blue : const Color(0xFF2C2C2E),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 message,
//                 style: const TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF2C2C2E),
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: TextField(
//                 keyboardType: TextInputType.text,
//                 controller: _messageController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   hintStyle: TextStyle(color: Colors.grey),
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => _sendMessage(),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.blue,
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.send, color: Colors.white),
//               onPressed: _sendMessage,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
