import 'dart:io';
import 'package:cric_snap/players/model.dart';
import 'package:cric_snap/players/view_model.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:cric_snap/teams/view.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:cric_snap/widget/custom_button.dart';
import 'package:cric_snap/widget/custom_text_field.dart';
import 'package:cric_snap/widget/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});
  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final TextEditingController _searchController = TextEditingController();

  static bool _isPlaceholderTeam(Team? team) =>
      team != null && team.teamName.toLowerCase() == 'unassigned';
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final playerViewModel = context.read<PlayerViewModel>();
      final teamViewModel = context.read<TeamViewModel>();

      await playerViewModel.loadPlayers();
      if (!mounted) return;
      await teamViewModel.loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerViewModel = context.watch<PlayerViewModel>();
    final teamViewModel = context.watch<TeamViewModel>();
    final filteredPlayers = playerViewModel.players.where((player) {
      return player.fullName.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
    }).toList();
    return Scaffold(
      appBar: const CustomAppBar(title: 'Players'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateOrEditBottomSheet(context);
        },

        icon: const Icon(Icons.add),
        label: const Text('Add Player'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search players...',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: filteredPlayers.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.person,
                    title: 'No Players Found',
                    subtitle: 'Create players and assign them to teams.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      Team? playerTeam;
                      try {
                        playerTeam = teamViewModel.teams.firstWhere(
                          (team) => team.teamId == player.teamId,
                        );
                      } catch (_) {}
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: player.avatarPath != null
                                ? FileImage(File(player.avatarPath!))
                                : null,
                            child: player.avatarPath == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            player.fullName,

                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _isPlaceholderTeam(playerTeam)
                                ? 'No team'
                                : (playerTeam?.teamName ?? 'No team'),
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showCreateOrEditBottomSheet(
                                  context,
                                  player: player,
                                );
                              }
                              if (value == 'delete') {
                                await playerViewModel.deletePlayer(
                                  player.playerId,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateOrEditBottomSheet(BuildContext context, {Player? player}) {
    final firstNameController = TextEditingController(
      text: player?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: player?.lastName ?? '',
    );
    Team? selectedTeam;
    if (player != null) {
      try {
        final t = context.read<TeamViewModel>().teams.firstWhere(
          (team) => team.teamId == player.teamId,
        );
        selectedTeam = _isPlaceholderTeam(t) ? null : t;
      } catch (_) {
        selectedTeam = null;
      }
    }
    String? imagePath = player?.avatarPath;
    String? firstNameError;
    String? lastNameError;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player == null ? 'Create Player' : 'Edit Player',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: imagePath != null
                          ? FileImage(File(imagePath!))
                          : null,
                      child: imagePath == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedImage != null) {
                          setModalState(() {
                            imagePath = pickedImage.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Choose Player Image'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: firstNameController,
                      hint: 'First Name',
                      prefixIcon: Icons.person_outline,
                      errorText: firstNameError,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: lastNameController,
                      hint: 'Last Name',
                      prefixIcon: Icons.person,
                      errorText: lastNameError,
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Team (optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedTeam == null
                                  ? 'No team selected'
                                  : selectedTeam!.teamName,
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedTeam == null
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDialog<Team>(
                                context: context,
                                builder: (_) => Dialog(
                                  child: TeamView(isSelectionMode: true),
                                ),
                              );
                              if (picked == null) return;
                              setModalState(() {
                                selectedTeam = picked;
                              });
                            },
                            icon: const Icon(Icons.groups),
                            label: const Text('Choose'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      title: player == null ? 'Create Player' : 'Update Player',
                      icon: Icons.save,
                      onPressed: () async {
                        final firstName = firstNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        setModalState(() {
                          firstNameError = firstName.isEmpty
                              ? 'First name is required'
                              : null;
                          lastNameError = lastName.isEmpty
                              ? 'Last name is required'
                              : null;
                        });
                        if (firstName.isEmpty || lastName.isEmpty) {
                          return;
                        }
                        final resolvedTeam =
                            selectedTeam ??
                            await _getOrCreateUnassignedTeam(context);
                        if (!context.mounted) return;
                        final playerModel = Player(
                          playerId: player?.playerId,
                          firstName: firstName,
                          lastName: lastName,
                          teamId: resolvedTeam.teamId,
                          avatarPath: imagePath,
                        );
                        final viewModel = context.read<PlayerViewModel>();
                        if (player == null) {
                          await viewModel.addPlayer(playerModel);
                        } else {
                          await viewModel.updatePlayer(playerModel);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Team> _getOrCreateUnassignedTeam(BuildContext context) async {
    final teamViewModel = context.read<TeamViewModel>();

    try {
      return teamViewModel.teams.firstWhere(
        (team) => team.teamName.toLowerCase() == 'unassigned',
      );
    } catch (_) {
      final unassignedTeam = Team(teamName: 'Unassigned', abbreviation: 'NA');
      await teamViewModel.addTeam(unassignedTeam);
      return unassignedTeam;
    }
  }
}
