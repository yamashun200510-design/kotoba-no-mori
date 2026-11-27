import 'package:flutter/material.dart';

/// 森の「おたより掲示板」風のお知らせ画面。
///
/// 既存ファイルには依存しない自己完結ウィジェットです。本体への組み込みは
/// Codexの作業完了後に行います（組み込み方法はファイル末尾のメモ参照）。
///
/// 使い方（最小）:
///   const NoticeScreen()                      // 内蔵の仮データで表示
///   NoticeScreen(notices: yourList)           // 独自データで表示
///   NoticeScreen(onReadChanged: (count) {})   // 未読数の変化を受け取る

// 世界観トークン（既存 main.dart / letter_board.dart と同値を独立定義）。
const _green = Color(0xFF35634C);
const _cream = Color(0xFFFAF6EA);
const _ink = Color(0xFF3B4A3F);
const _soft = Color(0xFF6A7A6D);

/// お知らせの種類。ラベル・色・アイコンをまとめて持つ。
enum NoticeKind {
  update('アップデート', Color(0xFF5B8C6A), Color(0xFFE7F1E6), Icons.auto_awesome),
  event('イベント', Color(0xFFCB7A3E), Color(0xFFFBEAD6), Icons.celebration),
  present('プレゼント', Color(0xFFC46A86), Color(0xFFF8E1E8), Icons.card_giftcard);

  const NoticeKind(this.label, this.color, this.chip, this.icon);
  final String label;
  final Color color; // 濃い色（文字・アイコン・未読印）
  final Color chip; // 淡い色（バッジ背景）
  final IconData icon;
}

/// 1件のお知らせ。
class Notice {
  final String title;
  final String body;
  final DateTime date;
  final NoticeKind kind;
  final bool unread;
  const Notice({
    required this.title,
    required this.body,
    required this.date,
    required this.kind,
    this.unread = false,
  });

  Notice copyWith({bool? unread}) => Notice(
    title: title,
    body: body,
    date: date,
    kind: kind,
    unread: unread ?? this.unread,
  );
}

/// 仮データ（新しい順に並べる前提。画面側でも日付降順に整列します）。
List<Notice> get sampleNotices => _defaultNotices();

class NoticeScreen extends StatefulWidget {
  final List<Notice>? notices;
  final ValueChanged<int>? onReadChanged; // 未読数が変わったら通知
  const NoticeScreen({super.key, this.notices, this.onReadChanged});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late List<Notice> _items;

  @override
  void initState() {
    super.initState();
    _items = [...(widget.notices ?? _defaultNotices())]
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _unreadCount => _items.where((n) => n.unread).length;

  void _markRead(int index) {
    if (!_items[index].unread) return;
    setState(() => _items[index] = _items[index].copyWith(unread: false));
    widget.onReadChanged?.call(_unreadCount);
  }

  void _markAllRead() {
    if (_unreadCount == 0) return;
    setState(() {
      _items = [for (final n in _items) n.copyWith(unread: false)];
    });
    widget.onReadChanged?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _board(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _NoticeCard(notice: _items[i], onTap: () => _markRead(i)),
            ),
          ),
        ],
      ),
    );
  }

  /// 木製看板風のヘッダー。
  Widget _board() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9A6B3F), Color(0xFF7E5531)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF5E3E22), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33402A17),
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.mail, color: Color(0xFFFFF3DA), size: 26),
              SizedBox(width: 10),
              Text(
                'おたより掲示板',
                style: TextStyle(
                  fontFamily: 'ZenMaru',
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFF7E6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _unreadCount > 0 ? '未読が $_unreadCount 件あります' : 'すべて読みました',
                style: const TextStyle(fontSize: 16, color: _soft),
              ),
            ),
            if (_unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all, size: 20),
                label: const Text(
                  'すべて既読',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(foregroundColor: _green),
              ),
          ],
        ),
      ],
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;
  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final k = notice.kind;
    return Semantics(
      button: true,
      label:
          '${k.label}のお知らせ、${notice.title}${notice.unread ? '、未読' : ''}',
      child: Material(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: notice.unread ? k.color.withValues(alpha: .55) : const Color(0xFFE4DEC9),
                width: notice.unread ? 2 : 1.4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _kindChip(k),
                    const Spacer(),
                    Text(
                      _formatDate(notice.date),
                      style: const TextStyle(fontSize: 15, color: _soft),
                    ),
                    if (notice.unread) ...[
                      const SizedBox(width: 8),
                      _unreadDot(k.color),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  notice.title,
                  style: TextStyle(
                    fontFamily: 'ZenMaru',
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: notice.unread ? _ink : const Color(0xFF55615A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.body,
                  style: const TextStyle(fontSize: 17, height: 1.6, color: _ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kindChip(NoticeKind k) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: k.chip,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(k.icon, size: 18, color: k.color),
        const SizedBox(width: 6),
        Text(
          k.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: k.color,
          ),
        ),
      ],
    ),
  );

  Widget _unreadDot(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .4), blurRadius: 5),
      ],
    ),
  );
}

String _formatDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

List<Notice> _defaultNotices() => [
  Notice(
    kind: NoticeKind.present,
    unread: true,
    title: 'ログインボーナスが増えました',
    body: '7日つづけて遊ぶと、うさぎから大きな贈り物が届きます。'
        '毎日の小さな楽しみに、ぜひお立ち寄りください。',
    date: DateTime(2026, 10, 24),
  ),
  Notice(
    kind: NoticeKind.event,
    unread: true,
    title: '秋のことばイベント開催中',
    body: '「もみじ」「どんぐり」など、秋の季節のことばが登場します。'
        '期間中に見つけて、森を秋色に染めましょう。',
    date: DateTime(2026, 10, 22),
  ),
  Notice(
    kind: NoticeKind.update,
    title: 'ステージマップが新しくなりました',
    body: '小道に沿ってステージが並び、どこまで進んだか一目で分かります。'
        '星を集めて、森のおくへ進んでみてください。',
    date: DateTime(2026, 10, 20),
  ),
  Notice(
    kind: NoticeKind.update,
    title: 'ことばが増えました',
    body: '3文字・4文字のことばをたくさん追加しました。'
        'いろいろな組み合わせで、ゆっくりお楽しみください。',
    date: DateTime(2026, 10, 15),
  ),
  Notice(
    kind: NoticeKind.event,
    title: 'はじまりのプレゼント',
    body: 'ゲームを始めてくれた みなさんへ、コインを贈りました。'
        '「わたしの森」で、好きな草花をむかえてあげてください。',
    date: DateTime(2026, 10, 10),
  ),
];
