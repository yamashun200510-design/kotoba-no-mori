import 'package:flutter/material.dart';

/// A picture-book shop entrance. The illustration is kept separate from its
/// tappable Flutter label so it remains responsive at every screen size.
class ForestShopHouse extends StatelessWidget {
  final VoidCallback onTap;
  const ForestShopHouse({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '森の小さなお店。タップしてお買いもの',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('forest-shop-house'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 194,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBFE6C0), Color(0xFFF4E9B4)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF6A9C62),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/art/forest-shop-cottage.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9A6A38),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x603B2917),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    '森の小さなお店　›',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF573A20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
