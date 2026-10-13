// SPDX-License-Identifier: GPL-2.0-or-later
const fs = require('fs');
const path = require('path');
const assert = require('assert/strict');
const { groups, key, files } = require('../tests/localization/swift_strings.cjs');
const root = path.resolve(__dirname, '..');
function catalog(file) {
    const entries = new Map();
    for (const line of fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, '').split(/\r?\n/)) {
        if (!line.trim() || line.startsWith('/*')) continue;
        const match = line.match(/^("(?:[^"\\]|\\.)*") = ("(?:[^"\\]|\\.)*");$/);
        assert(match, `Invalid .strings syntax: ${file}: ${line}`);
        const k = JSON.parse(match[1]), value = JSON.parse(match[2]);
        assert(!entries.has(k), `Duplicate key: ${k}`);
        assert(value.trim(), `Empty translation: ${k}`);
        entries.set(k, value);
    }
    return entries;
}
const english = catalog('src/app/Shared/en.lproj/Localizable.strings');
const chinese = catalog('src/app/Shared/zh-Hans.lproj/Localizable.strings');
assert.deepEqual([...english.keys()].sort(), [...chinese.keys()].sort(), 'English and Chinese keys differ');
const formats = s => (s.match(/%%|%@/g) || []).filter(x => x === '%@').length;
for (const [k, en] of english) {
    const zh = chinese.get(k);
    assert.equal(formats(en), formats(zh), `Placeholder mismatch: ${k}`);
    if (k.includes('%@')) {
        for (const text of [en, zh]) assert(!/%/.test(text.replace(/%%|%@/g, '')), `Unsafe format: ${text}`);
    }
}
let calls = 0;
for (const file of files(path.join(root, 'src/app'))) {
    if (file.includes('Frameworks')) continue;
    const source = fs.readFileSync(file, 'utf8');
    for (const token of groups(source)) {
        if (!/HuskL10n\.render\(\s*$/.test(source.slice(Math.max(0, token.start - 30), token.start))) continue;
        const k = key(token.raw).replace(/\\u\{([0-9a-f]+)\}/gi, (_, code) => String.fromCodePoint(parseInt(code, 16)));
        assert(english.has(k), `Missing key: ${path.relative(root, file)}: ${k}`);
        calls++;
    }
}
const spec = fs.readFileSync(path.join(root, 'src/app/project.yml'), 'utf8');
assert(spec.includes('developmentLanguage: en'));
assert.equal((spec.match(/- path: Shared\s/g) || []).length, 2, 'App and widget must both include Shared');
assert(spec.includes('HUSK_BUNDLE_IDENTIFIER: com.husk.app'), 'Existing Bundle ID must be preserved');
for (const lang of ['en', 'zh-Hans']) assert(catalog(`src/app/Husk/${lang}.lproj/InfoPlist.strings`).has('NSLocalNetworkUsageDescription'));
console.log(`PASS: ${english.size} matching catalog entries; ${calls} localized source expressions; app/widget resources; existing Bundle ID`);
