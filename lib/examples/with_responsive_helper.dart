import 'package:flutter/material.dart';
import 'package:chat_apps/utils/responsive_helper.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';

/// ✅ WITH ResponsiveHelper - Clean, maintainable, consistent code
/// This is what you write with ResponsiveHelper

class ChatListPageWithHelper extends StatelessWidget {
  final List<UserModel> users;
  final List<MessageModel> messages;

  const ChatListPageWithHelper({
    super.key,
    required this.users,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Column(
        children: [
          // ✅ Clean responsive header
          _ResponsiveHeader(),

          // ✅ Clean responsive search bar
          _ResponsiveSearchBar(),

          // ✅ Clean responsive chat list
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _ChatTileWithHelper(user: users[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ WITH ResponsiveHelper - Clean, reusable component
class _ResponsiveHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.getSmallAvatarSize(context) / 2,
            backgroundColor: const Color(0xFF0D7FF2),
          ),
          Expanded(
            child: Text(
              'Chats',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.getHeadingFontSize(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: ResponsiveHelper.getSmallAvatarSize(context),
            height: ResponsiveHelper.getSmallAvatarSize(context),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getSmallAvatarSize(context) / 2,
              ),
            ),
            child: Icon(
              Icons.chat,
              color: Colors.white,
              size: ResponsiveHelper.getSmallAvatarSize(context) * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ WITH ResponsiveHelper - Clean, reusable search bar
class _ResponsiveSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getPadding(context),
      ),
      child: Container(
        height: ResponsiveHelper.getSearchBarHeight(context),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getBorderRadius(context) * 1.5,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getPadding(context),
              vertical: ResponsiveHelper.getSearchBarHeight(context) * 0.1,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey,
              size: ResponsiveHelper.getIconSize(context),
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
          ),
        ),
      ),
    );
  }
}

/// ✅ WITH ResponsiveHelper - Clean, reusable chat tile
class _ChatTileWithHelper extends StatelessWidget {
  final UserModel user;

  const _ChatTileWithHelper({required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getListTilePadding(context),
          vertical: ResponsiveHelper.getListTileVerticalPadding(context),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getBorderRadius(context),
          ),
        ),
        child: Row(
          children: [
            // ✅ Clean avatar sizing
            CircleAvatar(
              radius: ResponsiveHelper.getAvatarSize(context) / 2,
              backgroundImage: NetworkImage(
                user.profilePictureUrl ?? 'https://example.com/default.jpg',
              ),
            ),

            SizedBox(width: ResponsiveHelper.getMargin(context) * 2),

            // ✅ Clean text sizing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.username,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getTitleFontSize(
                              context,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '2m ago',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: ResponsiveHelper.getCaptionFontSize(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getMargin(context)),
                  Text(
                    'Last message preview...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: ResponsiveHelper.isDesktop(context) ? 2 : 1,
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

/// ✅ WITH ResponsiveHelper - Clean, reusable button
class ResponsiveButtonWithHelper extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ResponsiveButtonWithHelper({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.getButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D7FF2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.getTitleFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ✅ WITH ResponsiveHelper - Clean, reusable grid
class ResponsiveGridWithHelper extends StatelessWidget {
  final List<String> items;

  const ResponsiveGridWithHelper({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getCrossAxisCount(context),
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.2 : 1.0,
        crossAxisSpacing: ResponsiveHelper.getMargin(context),
        mainAxisSpacing: ResponsiveHelper.getMargin(context),
      ),
      itemBuilder: (context, index) {
        return _GridItemWithHelper(item: items[index]);
      },
      itemCount: items.length,
    );
  }
}

/// ✅ WITH ResponsiveHelper - Clean, reusable grid item
class _GridItemWithHelper extends StatelessWidget {
  final String item;

  const _GridItemWithHelper({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getSmallPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context),
        ),
      ),
      child: Center(
        child: Text(
          item,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
