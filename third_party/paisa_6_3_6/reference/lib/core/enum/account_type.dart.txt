import 'package:flutter/material.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

part 'account_type.g.dart';

@HiveType(typeId: 12)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  wallet;
}

extension AccountTypeHelper on AccountType {
  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return MdiIcons.creditCard;
      case AccountType.wallet:
        return MdiIcons.walletBifold;
      case AccountType.cash:
        return MdiIcons.cashMultiple;
    }
  }
}
