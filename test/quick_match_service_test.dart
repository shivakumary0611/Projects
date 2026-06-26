import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/services/quick_match_constants.dart';
import 'package:cric_snap/services/quick_match_data_source.dart';
import 'package:cric_snap/services/quick_match_service.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as m;

@GenerateMocks([QuickMatchDataSource])
import 'quick_match_service_test.mocks.dart';

void main() {
  late MockQuickMatchDataSource mockDs;

  setUp(() {
    mockDs = MockQuickMatchDataSource();
  });

  test('start uses session letters Team A(D)/Team B(D) when next index is 4',
      () async {
    const n = 4;
    final teamA = Team(
      teamId: 'a1',
      teamName: quickMatchTeamAName(n),
      abbreviation: quickMatchTeamAAbbrev(n),
    );
    final teamB = Team(
      teamId: 'b1',
      teamName: quickMatchTeamBName(n),
      abbreviation: quickMatchTeamBAbbrev(n),
    );

    m.when(mockDs.nextQuickMatchNumber()).thenAnswer((_) async => n);

    m.when(
      mockDs.getOrCreateQuickTeam(
        teamName: quickMatchTeamAName(n),
        abbreviation: quickMatchTeamAAbbrev(n),
      ),
    ).thenAnswer(
      (_) async => QuickTeamResolution(team: teamA, alreadyExisted: false),
    );
    m.when(
      mockDs.getOrCreateQuickTeam(
        teamName: quickMatchTeamBName(n),
        abbreviation: quickMatchTeamBAbbrev(n),
      ),
    ).thenAnswer(
      (_) async => QuickTeamResolution(team: teamB, alreadyExisted: false),
    );

    m.when(mockDs.insertMatch(m.argThat(isA<MatchModel>()))).thenAnswer(
      (_) async {},
    );
    m.when(mockDs.insertInnings(m.argThat(isA<Innings>()))).thenAnswer(
      (_) async {},
    );

    final service = QuickMatchService(mockDs);
    final result = await service.start(overs: 7);

    expect(result.quickMatchNumber, n);
    expect(result.teamA.teamId, teamA.teamId);
    expect(result.teamB.teamId, teamB.teamId);
    expect(result.match.homeTeamId, teamA.teamId);
    expect(result.match.awayTeamId, teamB.teamId);
    expect(result.match.oversPerInnings, 7);

    final capturedInnings =
        m.verify(mockDs.insertInnings(m.captureAny)).captured;
    expect(capturedInnings, hasLength(2));
    expect((capturedInnings[0] as Innings).teamId, teamA.teamId);
    expect((capturedInnings[1] as Innings).teamId, teamB.teamId);

    m.verify(mockDs.insertMatch(m.argThat(isA<MatchModel>()))).called(1);
    m.verify(mockDs.nextQuickMatchNumber()).called(1);
  });
}
