import 'package:flutter/material.dart';
import '../../common/user_data.dart';
import '../setting/myinfo.dart';

class ProfileSection extends StatelessWidget {
  final VoidCallback onRefresh;

  const ProfileSection({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF5F5F5),
              child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                  ? const Icon(Icons.person_outline, size: 35, color: Colors.grey)
                  : ClipOval(
                child: Image.network(
                  UserData.profileImagePath!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_outline, size: 35, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                UserData.nickname ?? '로딩중...',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyInfoScreen()),
                ).then((_) => onRefresh());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('수정', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 76.0),
          child: Text('좋아요 0   스크랩 0', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}