import 'dart:io';
import 'package:cric_snap/teams/model.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:cric_snap/widget/custom_button.dart';
import 'package:cric_snap/widget/custom_text_field.dart';
import 'package:cric_snap/widget/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class TeamView extends StatefulWidget {
  final bool isSelectionMode;
  const TeamView({super.key, this.isSelectionMode = false});
  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final TextEditingController _searchController = TextEditingController();

  /// Placeholder team used for players with no squad; not shown in team lists.
  static bool _isPlaceholderTeam(Team team) =>
      team.teamName.toLowerCase() == 'unassigned';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeamViewModel>().loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TeamViewModel>();
    final filteredTeams =
        viewModel.teams.where((team) => !_isPlaceholderTeam(team)).where((
          team,
        ) {
          return team.teamName.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              team.abbreviation.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );
        }).toList()..sort(
          (a, b) =>
              a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase()),
        );
    return Scaffold(
      appBar: const CustomAppBar(title: 'Teams'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateOrEditBottomSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search teams...',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: filteredTeams.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.groups,
                    title: 'No Teams Found',
                    subtitle: 'Create your first cricket team to get started.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: team.teamLogo != null
                                ? FileImage(File(team.teamLogo!))
                                : null,
                            child: team.teamLogo == null
                                ? const Icon(Icons.groups)
                                : null,
                          ),
                          title: Text(
                            team.teamName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(team.abbreviation),
                          ),
                          trailing: widget.isSelectionMode
                              ? const Icon(Icons.arrow_forward_ios, size: 18)
                              : PopupMenuButton(
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
                                        team: team,
                                      );
                                    }
                                    if (value == 'delete') {
                                      await viewModel.deleteTeam(team.teamId);
                                    }
                                  },
                                ),
                          onTap: () {
                            if (widget.isSelectionMode) {
                              Navigator.pop(context, team);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateOrEditBottomSheet(BuildContext context, {Team? team}) {
    final teamNameController = TextEditingController(
      text: team?.teamName ?? '',
    );
    final abbreviationController = TextEditingController(
      text: team?.abbreviation ?? '',
    );
    String? imagePath = team?.teamLogo;
    String? teamNameError;
    String? abbreviationError;
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
                      team == null ? 'Create Team' : 'Edit Team',
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
                          ? const Icon(Icons.groups, size: 40)
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
                      label: const Text('Choose Team Logo'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: teamNameController,
                      hint: 'Team Name',
                      prefixIcon: Icons.groups,
                      errorText: teamNameError,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: abbreviationController,
                      hint: 'Abbreviation',
                      prefixIcon: Icons.short_text,
                      errorText: abbreviationError,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      title: team == null ? 'Create Team' : 'Update Team',
                      icon: Icons.save,
                      onPressed: () async {
                        final teamName = teamNameController.text.trim();
                        final abbreviation = abbreviationController.text.trim();
                        setModalState(() {
                          teamNameError = teamName.isEmpty
                              ? 'Team name is required'
                              : null;
                          abbreviationError = abbreviation.isEmpty
                              ? 'Abbreviation is required'
                              : null;
                        });
                        if (teamName.isEmpty || abbreviation.isEmpty) {
                          return;
                        }
                        final teamModel = Team(
                          teamId: team?.teamId,
                          teamName: teamName,
                          abbreviation: abbreviation,
                          teamLogo: imagePath,
                        );
                        final viewModel = context.read<TeamViewModel>();
                        if (team == null) {
                          await viewModel.addTeam(teamModel);
                        } else {
                          await viewModel.updateTeam(teamModel);
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
}
