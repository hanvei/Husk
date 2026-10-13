// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

let chinese = CommandLine.arguments.contains("--chinese")
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    guard condition() else { fatalError("FAILED: \(name)") }
}
check(HuskL10n.text("Settings") == (chinese ? "设置" : "Settings"), "language selection")
check(HuskL10n.text("Untranslated text") == "Untranslated text", "English fallback")
let name = "测试 Game %@ 50%"
check(HuskL10n.render("Version \(name)") == (chinese ? "版本 \(name)" : "Version \(name)"), "Unicode and percent in arguments")
check(HuskL10n.render("Unknown \(name) 100%") == "Unknown \(name) 100%", "interpolated fallback and literal percent")
check(HuskL10n.render("50%") == "50%", "static literal percent")
let old = "That backup is of Game A, not Game B."
check(HuskL10n.text(old) == (chinese ? "此备份属于 Game A，不属于 Game B。" : old), "saved English diagnostic")
let unrelated = "A server error from an unknown provider"
check(HuskL10n.text(unrelated) == unrelated, "unknown external error preserved")
check(HuskL10n.render("Search \(123) apps") == (chinese ? "搜索 123 个应用" : "Search 123 apps"), "integer interpolation")
check(HuskL10n.text("Sending Game — 42%") == (chinese ? "正在发送 Game — 42%" : "Sending Game — 42%"), "runtime progress percent")
print("PASS: \(chinese ? "zh-Hans" : "English/fallback") localization")
