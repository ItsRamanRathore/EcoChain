import 'package:hive_flutter/hive_flutter.dart';
import '../../models/local/lot_local.dart';
class HiveBoxes {
  static const String pendingLots = 'pending_lots';
  static const String pendingTransactions = 'pending_transactions';
  static const String priceBoard = 'price_board';
  static const String userSession = 'user_session';
  static const String cachedPrices = 'cached_prices'; // price board offline cache
}

class HiveSetup {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters here once generated
    Hive.registerAdapter(LotLocalAdapter());
    
    // Open boxes
    await Hive.openBox(HiveBoxes.pendingLots);
    await Hive.openBox(HiveBoxes.pendingTransactions);
    await Hive.openBox(HiveBoxes.priceBoard);
    await Hive.openBox(HiveBoxes.userSession);
    await Hive.openBox(HiveBoxes.cachedPrices);
  }
}
