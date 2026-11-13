import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'cutout.dart';
import 'cutout_page.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final _licenses = _loadLicenses();

  Future<Map<String, List<List<LicenseParagraph>>>> _loadLicenses() async {
    final packages = <String, List<List<LicenseParagraph>>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final paragraphs = entry.paragraphs.toList();
      for (final package in entry.packages) {
        (packages[package] ??= []).add(paragraphs);
      }
    }
    return packages;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _licenses,
    builder: (context, snapshot) {
      final packages = snapshot.data;
      // Keep the registry's first (application) package first, as LicensePage does.
      final names = packages?.keys.toList() ?? [];
      if (names.isNotEmpty) {
        final first = names.removeAt(0);
        names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        names.insert(0, first);
      }
      final localizations = MaterialLocalizations.of(context);
      return CutoutPage(
        title: localizations.licensesPageTitle,
        children: [
          CutoutSurface(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Powered by Flutter', textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (snapshot.hasError)
            CutoutSurface(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    const Icon(Icons.error_outline),
                    Text(snapshot.error.toString()),
                  ],
                ),
              ),
            )
          else if (packages == null)
            const CutoutSurface(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final name in names) ...[
              CutoutAction(
                style: CutoutActionStyle.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        _LicenseDetails(name: name, licenses: packages[name]!),
                  ),
                ),
                child: Column(
                  children: [
                    Text(name, textAlign: TextAlign.center),
                    Text(
                      localizations.licensesPackageDetailText(
                        packages[name]!.length,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      );
    },
  );
}

class _LicenseDetails extends StatelessWidget {
  _LicenseDetails({required this.name, required this.licenses})
    : paragraphs = licenses.expand((entry) => entry).toList();

  final String name;
  final List<List<LicenseParagraph>> licenses;
  final List<LicenseParagraph> paragraphs;

  @override
  Widget build(BuildContext context) => CutoutPage(
    title: name,
    sliverBody: SliverList.builder(
      itemCount: paragraphs.length,
      itemBuilder: (context, index) {
        final paragraph = paragraphs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CutoutSurface(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: paragraph.indent < 0 ? 0 : 16.0 * paragraph.indent,
              ),
              child: Text(
                paragraph.text,
                textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                    ? TextAlign.center
                    : TextAlign.start,
                style: paragraph.indent == LicenseParagraph.centeredIndent
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
          ),
        );
      },
    ),
    children: [
      Text(
        MaterialLocalizations.of(context)
            .licensesPackageDetailText(licenses.length),
      ),
    ],
  );
}
