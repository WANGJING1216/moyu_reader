import '../domain/entities/fake_chat_message.dart';

class ReaderFakeData {
  static const String contactAvatar = '🌸';
  static const String selfAvatar = '😊';
  static const String readingAvatar = contactAvatar;

  static const List<FakeChatMessage> chatMessages = <FakeChatMessage>[
    FakeChatMessage(
      role: FakeChatRole.left,
      text: '你这两天怎么一直盯着手机？',
      avatar: contactAvatar,
      timestamp: '上午 8:12',
    ),
    FakeChatMessage(
      role: FakeChatRole.right,
      text: '在看项目日志，领导催得紧。',
      avatar: selfAvatar,
    ),
    FakeChatMessage(
      role: FakeChatRole.left,
      text: '中午要不要一起去楼下吃面？',
      avatar: contactAvatar,
    ),
    FakeChatMessage(
      role: FakeChatRole.right,
      text: '我先把这段看完，马上来。',
      avatar: selfAvatar,
    ),
    FakeChatMessage(
      role: FakeChatRole.left,
      text: '行，那我先占个位。',
      avatar: contactAvatar,
      timestamp: '上午 8:35',
    ),
    FakeChatMessage(
      role: FakeChatRole.right,
      text: '收到，十分钟到。',
      avatar: selfAvatar,
    ),
  ];

  static const String novelParagraph =
      '雨落在旧城墙上，像有人在远处轻轻敲鼓。\n\n'
      '程野把风衣领口往上提了提，沿着巷子往里走。路灯坏了半盏，'
      '光影被雨丝扯成细碎的线，落在积水里，映出摇晃的人影。\n\n'
      '他知道今晚不会太平。那封没有署名的短信只写了七个字：'
      '“旧码头，带上钥匙。”\n\n'
      '钥匙在他口袋里，冰凉得像一小块金属做成的月亮。';
}
