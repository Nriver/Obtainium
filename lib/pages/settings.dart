import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// Generates a random light color
// Courtesy of ChatGPT 😭 (with a bugfix 🥳)
Color generateRandomLightColor() {
  // Create a random number generator
  final Random random = Random();

  // Generate random hue, saturation, and value values
  final double hue = random.nextDouble() * 360;
  final double saturation = 0.5 + random.nextDouble() * 0.5;
  final double value = 0.9 + random.nextDouble() * 0.1;

  // Create a HSV color with the random values
  return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    SourceProvider sourceProvider = SourceProvider();
    AppsProvider appsProvider = context.read<AppsProvider>();
    if (settingsProvider.prefs == null) {
      settingsProvider.initializeSettings();
    }

    var themeDropdown = DropdownButtonFormField(
        decoration: InputDecoration(labelText: tr('theme')),
        value: settingsProvider.theme,
        items: [
          DropdownMenuItem(
            value: ThemeSettings.dark,
            child: Text(tr('dark')),
          ),
          DropdownMenuItem(
            value: ThemeSettings.light,
            child: Text(tr('light')),
          ),
          DropdownMenuItem(
            value: ThemeSettings.system,
            child: Text(tr('followSystem')),
          )
        ],
        onChanged: (value) {
          if (value != null) {
            settingsProvider.theme = value;
          }
        });

    var colourDropdown = DropdownButtonFormField(
        decoration: InputDecoration(labelText: tr('colour')),
        value: settingsProvider.colour,
        items: [
          DropdownMenuItem(
            value: ColourSettings.basic,
            child: Text(tr('obtainium')),
          ),
          DropdownMenuItem(
            value: ColourSettings.materialYou,
            child: Text(tr('materialYou')),
          )
        ],
        onChanged: (value) {
          if (value != null) {
            settingsProvider.colour = value;
          }
        });

    var sortDropdown = DropdownButtonFormField(
        decoration: InputDecoration(labelText: tr('appSortBy')),
        value: settingsProvider.sortColumn,
        items: [
          DropdownMenuItem(
            value: SortColumnSettings.authorName,
            child: Text(tr('authorName')),
          ),
          DropdownMenuItem(
            value: SortColumnSettings.nameAuthor,
            child: Text(tr('nameAuthor')),
          ),
          DropdownMenuItem(
            value: SortColumnSettings.added,
            child: Text(tr('asAdded')),
          )
        ],
        onChanged: (value) {
          if (value != null) {
            settingsProvider.sortColumn = value;
          }
        });

    var orderDropdown = DropdownButtonFormField(
        decoration: InputDecoration(labelText: tr('appSortOrder')),
        value: settingsProvider.sortOrder,
        items: [
          DropdownMenuItem(
            value: SortOrderSettings.ascending,
            child: Text(tr('ascending')),
          ),
          DropdownMenuItem(
            value: SortOrderSettings.descending,
            child: Text(tr('descending')),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            settingsProvider.sortOrder = value;
          }
        });

    var intervalDropdown = DropdownButtonFormField(
        decoration: InputDecoration(labelText: tr('bgUpdateCheckInterval')),
        value: settingsProvider.updateInterval,
        items: updateIntervals.map((e) {
          int displayNum = (e < 60
                  ? e
                  : e < 1440
                      ? e / 60
                      : e / 1440)
              .round();
          String display = e == 0
              ? tr('neverManualOnly')
              : (e < 60
                  ? plural('minute', displayNum)
                  : e < 1440
                      ? plural('hour', displayNum)
                      : plural('day', displayNum));
          return DropdownMenuItem(value: e, child: Text(display));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            settingsProvider.updateInterval = value;
          }
        });

    var sourceSpecificFields = sourceProvider.sources.map((e) {
      if (e.additionalSourceSpecificSettingFormItems.isNotEmpty) {
        return GeneratedForm(
            items: e.additionalSourceSpecificSettingFormItems.map((e) {
              e.defaultValue = settingsProvider.getSettingString(e.key);
              return [e];
            }).toList(),
            onValueChanges: (values, valid, isBuilding) {
              if (valid) {
                values.forEach((key, value) {
                  settingsProvider.setSettingString(key, value);
                });
              }
            });
      } else {
        return Container();
      }
    });

    const height16 = SizedBox(
      height: 16,
    );

    var categories = settingsProvider.categories;

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(slivers: <Widget>[
          CustomAppBar(title: tr('settings')),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: settingsProvider.prefs == null
                      ? const SizedBox()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('appearance'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            themeDropdown,
                            height16,
                            colourDropdown,
                            height16,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: sortDropdown),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(child: orderDropdown),
                              ],
                            ),
                            height16,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('showWebInAppView')),
                                Switch(
                                    value: settingsProvider.showAppWebpage,
                                    onChanged: (value) {
                                      settingsProvider.showAppWebpage = value;
                                    })
                              ],
                            ),
                            height16,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('pinUpdates')),
                                Switch(
                                    value: settingsProvider.pinUpdates,
                                    onChanged: (value) {
                                      settingsProvider.pinUpdates = value;
                                    })
                              ],
                            ),
                            const Divider(
                              height: 16,
                            ),
                            height16,
                            Text(
                              tr('updates'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            intervalDropdown,
                            const Divider(
                              height: 48,
                            ),
                            Text(
                              tr('sourceSpecific'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            ...sourceSpecificFields,
                            const Divider(
                              height: 48,
                            ),
                            Text(
                              tr('categories'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            height16,
                            Wrap(
                              children: [
                                ...categories.entries.toList().map((e) {
                                  return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Chip(
                                        label: Text(e.key),
                                        backgroundColor: Color(e.value),
                                        visualDensity: VisualDensity.compact,
                                        onDeleted: () {
                                          showDialog<Map<String, dynamic>?>(
                                              context: context,
                                              builder: (BuildContext ctx) {
                                                return GeneratedFormModal(
                                                    title: tr(
                                                        'deleteCategoryQuestion'),
                                                    message: tr(
                                                        'categoryDeleteWarning',
                                                        args: [e.key]),
                                                    items: []);
                                              }).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                categories.remove(e.key);
                                                settingsProvider.categories =
                                                    categories;
                                              });
                                              appsProvider.saveApps(appsProvider
                                                  .apps.values
                                                  .where((element) =>
                                                      element.app.category ==
                                                      e.key)
                                                  .map((e) {
                                                var a = e.app;
                                                a.category = null;
                                                return a;
                                              }).toList());
                                            }
                                          });
                                        },
                                      ));
                                }),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: IconButton(
                                      onPressed: () {
                                        showDialog<Map<String, dynamic>?>(
                                            context: context,
                                            builder: (BuildContext ctx) {
                                              return GeneratedFormModal(
                                                  title: tr('addCategory'),
                                                  items: [
                                                    [
                                                      GeneratedFormTextField(
                                                          'label',
                                                          label: tr('label'))
                                                    ]
                                                  ]);
                                            }).then((value) {
                                          String? label = value?['label'];
                                          if (label != null) {
                                            setState(() {
                                              categories[label] =
                                                  generateRandomLightColor()
                                                      .value;
                                              settingsProvider.categories =
                                                  categories;
                                            });
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: tr('add'),
                                    ))
                              ],
                            )
                          ],
                        ))),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Divider(
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        launchUrlString(settingsProvider.sourceUrl,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.code),
                      label: Text(
                        tr('appSource'),
                      ),
                    ),
                    TextButton.icon(
                        onPressed: () {
                          context.read<LogsProvider>().get().then((logs) {
                            if (logs.isEmpty) {
                              showError(ObtainiumError(tr('noLogs')), context);
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext ctx) {
                                    return const LogsDialog();
                                  });
                            }
                          });
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: Text(tr('appLogs'))),
                  ],
                ),
                height16,
              ],
            ),
          )
        ]));
  }
}

class LogsDialog extends StatefulWidget {
  const LogsDialog({super.key});

  @override
  State<LogsDialog> createState() => _LogsDialogState();
}

class _LogsDialogState extends State<LogsDialog> {
  String? logString;
  List<int> days = [7, 5, 4, 3, 2, 1];

  @override
  Widget build(BuildContext context) {
    var logsProvider = context.read<LogsProvider>();
    void filterLogs(int days) {
      logsProvider
          .get(after: DateTime.now().subtract(Duration(days: days)))
          .then((value) {
        setState(() {
          String l = value.map((e) => e.toString()).join('\n\n');
          logString = l.isNotEmpty ? l : tr('noLogs');
        });
      });
    }

    if (logString == null) {
      filterLogs(days.first);
    }

    return AlertDialog(
      scrollable: true,
      title: Text(tr('appLogs')),
      content: Column(
        children: [
          DropdownButtonFormField(
              value: days.first,
              items: days
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(plural('day', e)),
                      ))
                  .toList(),
              onChanged: (d) {
                filterLogs(d ?? 7);
              }),
          const SizedBox(
            height: 32,
          ),
          Text(logString ?? '')
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('close'))),
        TextButton(
            onPressed: () {
              Share.share(logString ?? '', subject: tr('appLogs'));
              Navigator.of(context).pop();
            },
            child: Text(tr('share')))
      ],
    );
  }
}
