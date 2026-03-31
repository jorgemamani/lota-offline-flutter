import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_releases.dart';
import '../../domain/models/app_release.dart';
import '../../domain/models/release_note.dart';
import '../../../../shared/managers/alert_manager.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static final Uri _linkedInUri = Uri.parse(
    'https://www.linkedin.com/in/jorgemamani297/',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de la app'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Lota Pue',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bingo 90 Argentino',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final installedVersion = info?.version;
                final installedLabel = installedVersion == null
                    ? 'Cargando version...'
                    : 'v${info!.version}+${info.buildNumber}';
                final release = _resolveRelease(installedVersion);

                return Column(
                  children: [
                    if (!kIsWeb) ...[
                      _CompactVersionList(versionLabel: installedLabel),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: release == null
                          ? 'Version instalada incluye'
                          : 'Version ${release.version} incluye',
                      child: Column(
                        children: release == null
                            ? const [_EmptyReleaseNotes()]
                            : release.notes
                                .map((note) => _ReleaseNoteTile(note: note))
                                .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Desarrollada y creada por',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jorge Luis Mamani',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Desarrollador Flutter',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openLinkedIn(context),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ver LinkedIn'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLinkedIn(BuildContext context) async {
    bool opened;
    if (kIsWeb) {
      opened = await launchUrl(
        _linkedInUri,
        webOnlyWindowName: '_blank',
      );
    } else {
      opened = await launchUrl(
        _linkedInUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!opened) {
        opened = await launchUrl(
          _linkedInUri,
          mode: LaunchMode.externalApplication,
        );
      }
    }

    if (!opened) {
      AlertManager.showSnackBarWarning(
        message: 'No se pudo abrir el enlace de LinkedIn.',
      );
    }
  }

  AppRelease? _resolveRelease(String? installedVersion) {
    if (appReleases.isEmpty) return null;
    if (installedVersion == null) return appReleases.first;
    for (final release in appReleases) {
      if (release.version == installedVersion) return release;
    }
    return appReleases.first;
  }
}

class _CompactVersionList extends StatelessWidget {
  const _CompactVersionList({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          Icons.verified_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Version instalada'),
        subtitle: Text(
          versionLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyReleaseNotes extends StatelessWidget {
  const _EmptyReleaseNotes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'No hay notas disponibles para esta version.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReleaseNoteTile extends StatelessWidget {
  const _ReleaseNoteTile({required this.note});

  final ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
