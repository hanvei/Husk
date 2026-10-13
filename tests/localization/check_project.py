# SPDX-License-Identifier: GPL-2.0-or-later
"""Check actual XcodeGen target membership; run on macOS after generation."""
import json
import subprocess

project = 'src/app/Husk.xcodeproj/project.pbxproj'
objects = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', project]))['objects']
for name in ('Husk', 'HuskDownloadsWidget'):
    target = next(o for o in objects.values() if o.get('isa') == 'PBXNativeTarget' and o.get('name') == name)
    resources = []
    sources = []
    for phase_id in target['buildPhases']:
        phase = objects[phase_id]
        for file_id in phase.get('files', []):
            build_file = objects[file_id]
            ref = objects.get(build_file.get('fileRef'), {})
            if phase['isa'] == 'PBXResourcesBuildPhase':
                resources.append(ref)
            if phase['isa'] == 'PBXSourcesBuildPhase':
                sources.append(ref)
    assert any(o.get('path', '').endswith('HuskL10n.swift') for o in sources), name + ': helper missing'
    tables = ['Localizable.strings'] + (['InfoPlist.strings'] if name == 'Husk' else [])
    for table in tables:
        group = next(o for o in resources if o.get('name', o.get('path')) == table)
        languages = {objects[c].get('name') for c in group['children']}
        assert {'en', 'zh-Hans'} <= languages, (name, table, languages)
    print('PASS:', name, 'Swift helper and localized resource build phases')
