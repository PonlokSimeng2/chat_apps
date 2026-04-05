import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';

/// ❌ WITHOUT ResponsiveHelper - Manual responsive code everywhere
/// This is what you would write in EVERY widget without ResponsiveHelper

class ChatListPageWithoutHelper extends StatelessWidget {
  final List<UserModel> users;
  final List<MessageModel> messages;

  const ChatListPageWithoutHelper({
    super.key,
    required this.users,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    // ❌ Manual breakpoint detection in EVERY widget
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // ❌ Manual responsive calculations in EVERY widget
    final headerPadding = isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;
    final avatarSize = isDesktop
        ? 56.0
        : isTablet
        ? 48.0
        : 40.0;
    final titleFontSize = isDesktop
        ? 28.0
        : isTablet
        ? 24.0
        : 20.0;
    final searchHeight = isDesktop
        ? 60.0
        : isTablet
        ? 54.0
        : 48.0;
    final searchHorizontalPadding = isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;
    final searchBorderRadius = isDesktop ? 30.0 : 24.0;
    final searchFontSize = isDesktop ? 18.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Column(
        children: [
          // ❌ Manual responsive header
          Container(
            padding: EdgeInsets.all(headerPadding),
            child: Row(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                    image: const DecorationImage(
                      image: NetworkImage('https://example.com/avatar.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                  ),
                  child: Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: avatarSize * 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ❌ Manual responsive search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: searchHorizontalPadding),
            child: Container(
              height: searchHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(searchBorderRadius),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: searchHorizontalPadding),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: searchHeight * 0.4,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: searchFontSize,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: searchHorizontalPadding * 0.5,
                          vertical: searchHeight * 0.1,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: searchFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ❌ Manual responsive chat list
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _ChatTileWithoutHelper(user: users[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ❌ WITHOUT ResponsiveHelper - Repetitive responsive code in every component
class _ChatTileWithoutHelper extends StatelessWidget {
  final UserModel user;

  const _ChatTileWithoutHelper({required this.user});

  @override
  Widget build(BuildContext context) {
    // ❌ Same manual breakpoint detection AGAIN
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // ❌ Same manual calculations AGAIN
    final avatarSize = isDesktop
        ? 64.0
        : isTablet
        ? 60.0
        : 56.0;
    final horizontalPadding = isDesktop
        ? 20.0
        : isTablet
        ? 18.0
        : 16.0;
    final verticalPadding = isDesktop
        ? 16.0
        : isTablet
        ? 14.0
        : 12.0;
    final fontSizeName = isDesktop
        ? 18.0
        : isTablet
        ? 17.0
        : 16.0;
    final fontSizeMessage = isDesktop
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final fontSizeTime = isDesktop ? 14.0 : 12.0;

    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // ❌ Manual avatar sizing AGAIN
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(avatarSize / 2),
                image: DecorationImage(
                  image: NetworkImage(
                    user.profilePictureUrl ?? 'https://example.com/default.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: isDesktop ? 20 : 16),

            // ❌ Manual text sizing AGAIN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeName,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '2m ago',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: fontSizeTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last message preview...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: fontSizeMessage,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: isDesktop ? 2 : 1,
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

/// ❌ WITHOUT ResponsiveHelper - Manual responsive button
class ResponsiveButtonWithoutHelper extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ResponsiveButtonWithoutHelper({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // ❌ Same manual breakpoint detection YET AGAIN
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // ❌ Same manual calculations YET AGAIN
    final buttonHeight = isDesktop
        ? 56.0
        : isTablet
        ? 52.0
        : 48.0;
    final fontSize = isDesktop
        ? 18.0
        : isTablet
        ? 16.0
        : 14.0;
    final borderRadius = isDesktop
        ? 16.0
        : isTablet
        ? 14.0
        : 12.0;
    final horizontalPadding = isDesktop
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D7FF2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ❌ WITHOUT ResponsiveHelper - Manual responsive grid
class ResponsiveGridWithoutHelper extends StatelessWidget {
  final List<String> items;

  const ResponsiveGridWithoutHelper({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // ❌ Manual breakpoint detection EVERYWHERE
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // ❌ Manual grid calculations
    final crossAxisCount = isDesktop
        ? 4
        : isTablet
        ? 3
        : 2;
    final childAspectRatio = isDesktop
        ? 1.2
        : isTablet
        ? 1.1
        : 1.0;
    final crossAxisSpacing = isDesktop
        ? 16.0
        : isTablet
        ? 12.0
        : 8.0;
    final mainAxisSpacing = isDesktop
        ? 16.0
        : isTablet
        ? 12.0
        : 8.0;
    final padding = isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemBuilder: (context, index) {
        return _GridItemWithoutHelper(item: items[index]);
      },
      itemCount: items.length,
    );
  }
}

/// ❌ WITHOUT ResponsiveHelper - Manual responsive grid item
class _GridItemWithoutHelper extends StatelessWidget {
  final String item;

  const _GridItemWithoutHelper({required this.item});

  @override
  Widget build(BuildContext context) {
    // ❌ Manual breakpoint detection AGAIN AND AGAIN
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // ❌ Manual calculations AGAIN AND AGAIN
    final fontSize = isDesktop
        ? 16.0
        : isTablet
        ? 14.0
        : 12.0;
    final borderRadius = isDesktop
        ? 12.0
        : isTablet
        ? 10.0
        : 8.0;
    final padding = isDesktop
        ? 16.0
        : isTablet
        ? 12.0
        : 8.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          item,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
