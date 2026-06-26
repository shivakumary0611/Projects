import 'package:cric_snap/ballrecording/view_model.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/view_model.dart';
import 'package:cric_snap/players/view_model.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:provider/provider.dart';

final appProviders = [
  ChangeNotifierProvider<TeamViewModel>(create: (_) => TeamViewModel()),
  ChangeNotifierProvider<PlayerViewModel>(create: (_) => PlayerViewModel()),
  ChangeNotifierProvider<MatchesViewModel>(create: (_) => MatchesViewModel()),
  ChangeNotifierProvider<InningsViewModel>(create: (_) => InningsViewModel()),
  ChangeNotifierProvider<BallRecordingViewModel>(
    create: (_) => BallRecordingViewModel(),
  ),
];
