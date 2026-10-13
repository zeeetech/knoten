// Generated from a real sh.tangled.repo.pull patch blob. Do not hand edit.
//
// The text is the inflated `git format-patch` payload; the base64 is the same
// bytes gzipped, exactly as the PDS serves them.

let patchFixture = #"""
From 13a20d1e5616958728c9c791811a32a10c474e55 Mon Sep 17 00:00:00 2001
From: y3 <git@yarncat.moe>
Date: Thu, 24 Sep 2026 10:54:16 +0100
Subject: [PATCH] feat: wave visualizer rounding option

---
 src/lib/app/settings.svelte.ts              | 4 ++++
 src/lib/modals/SettingsAppearanceTab.svelte | 8 ++++++++
 src/lib/playback/Visualizer.svelte          | 79 ++++++++++++++++++++++++++++++++++++++++++++++-------------
 src/lib/languages/locales/ar.ts             | 1 +
 src/lib/languages/locales/bn.ts             | 1 +
 src/lib/languages/locales/cs.ts             | 1 +
 src/lib/languages/locales/da.ts             | 1 +
 src/lib/languages/locales/de.ts             | 1 +
 src/lib/languages/locales/el.ts             | 1 +
 src/lib/languages/locales/en.ts             | 1 +
 src/lib/languages/locales/es.ts             | 1 +
 src/lib/languages/locales/fi.ts             | 1 +
 src/lib/languages/locales/fil.ts            | 1 +
 src/lib/languages/locales/fr.ts             | 1 +
 src/lib/languages/locales/he.ts             | 1 +
 src/lib/languages/locales/hi.ts             | 1 +
 src/lib/languages/locales/id.ts             | 1 +
 src/lib/languages/locales/it.ts             | 1 +
 src/lib/languages/locales/ja.ts             | 1 +
 src/lib/languages/locales/ko.ts             | 1 +
 src/lib/languages/locales/nl.ts             | 1 +
 src/lib/languages/locales/no.ts             | 1 +
 src/lib/languages/locales/pl.ts             | 1 +
 src/lib/languages/locales/pt.ts             | 1 +
 src/lib/languages/locales/ro.ts             | 1 +
 src/lib/languages/locales/ru.ts             | 1 +
 src/lib/languages/locales/sv.ts             | 1 +
 src/lib/languages/locales/th.ts             | 1 +
 src/lib/languages/locales/tr.ts             | 1 +
 src/lib/languages/locales/uk.ts             | 1 +
 src/lib/languages/locales/vi.ts             | 1 +
 src/lib/languages/locales/zh-CN.ts          | 1 +
 src/lib/languages/locales/zh-TW.ts          | 1 +
 33 files changed, 103 insertions(+), 18 deletions(-)

diff --git a/src/lib/app/settings.svelte.ts b/src/lib/app/settings.svelte.ts
index 06282a7373b4390fe9c48ad3dab91637657c7f6d..6d0798fc72066f27fa26b7061cc4d4b00f24ac4a 100644
--- a/src/lib/app/settings.svelte.ts
+++ b/src/lib/app/settings.svelte.ts
@@ -264,6 +264,10 @@
 		validate: (v): v is number | null => v === null || typeof v === "number",
 	},
 	visualizer: { default: false },
+	visualizerRounding: {
+		default: false,
+		validate: (v): v is boolean => typeof v === "boolean",
+	},
 	visualizerSmoothing: { default: 0.5 },
 	visualizerBins: { default: 256 },
 	visualizerStyle: { default: "wave" as "bars" | "wave" | "oscilloscope" },
diff --git a/src/lib/modals/SettingsAppearanceTab.svelte b/src/lib/modals/SettingsAppearanceTab.svelte
index e2fa6ee2dbc5a8984de6459c67e58c6f429d56ee..b89bfcf1a798dfe35f06a4da9df4ef75383d3468 100644
--- a/src/lib/modals/SettingsAppearanceTab.svelte
+++ b/src/lib/modals/SettingsAppearanceTab.svelte
@@ -466,6 +466,14 @@
 			</div>
 		</div>
 		<div class="row">
+			<span>{t("settings.rounding")}</span>
+			<input
+				type="checkbox"
+				disabled={settings.visualizerStyle !== "wave"}
+				bind:checked={settings.visualizerRounding}
+			>
+		</div>
+		<div class="row">
 			<span
 				>{t("settings.stroke")}
 				(<span class="num">{settings.visualizerStroke}</span>)</span
"""#

let patchFixtureGzippedBase64 = """
H4sIAAAAAAAC/52WXY/iNhSGr8mvOM3VjBjASRwnQQNiu9WqN11VZdReVL048ceQJZNEcWCXHea/rxNgZkC04EYocZz3sc9x3uDzqS6fwAvQJ8KTIfNYEsaRH/OER4kXex4GPnqE04jKMITfygLmsgIvAkLG3Q98QjznkxlmDJsA7h+zZrbBuuDYDJ9KOXV+wUaO4WGxugOfdrRPfAYeGYd07DHoE48QZ75Kv0jejOHv3z88fPz1H1ASzd1XXEtYZ3qFefZd1lCXq0JkxSOUVZOVheMMBgMHdM1HeZaOsKpGWjaNEeihXsu8kcNGw9GxBQp9c7xRT6XAXI/me/BDVUmsseDyAdP9KIaKO+qYrHLcpMiXoz9fIzwA7+aLklf0umPw/nibLcficYWPUo/ykmNurlifprcFD/r/haSFNcK1NSLQHpHWiMztEfv0pX36KvsfyGkylxH7t7+wX+SFfS6ZsEcaa+SLvceWpTVS2HussJ+lsp+lsl+x2j6wemWN6LU10izsEXvzr5bWyNre/N8Xg4+fj6hrkIe/ziFBAOZ/QWrgCwNJcWd2zQCyQsu63f30Tf/WdMUgZC53HYNbxxGZUjAYmI0YcHRha0wvCJysEPIbEObHPkZBFKQ0SIiSCacxikBgmngsiFgY8UgxMRwyQaIkVjzyCWPKjxT6LI0I8zingqaEKJ8ip2gyIYzSdv++GKVj9sTLkc5mMPAZvTMVRXvxCMxmDvR6a7Mxi64GuVnfjmENmYZi9ZSaamJrGnkOk6npnUwmu7vtFppNJUu173R3YvfODPbSnt7KkTE8m7VXuMpNqaJMESHBKPrvFH/s6xWjNP29Y3ErPRteWpa5xKIN7DiU/QO3JU9imT+VZbPYTfUWFBmGcCL82fjnSOOH7FQzbza5PBK5bSXmAmoTBNbaNWu37zKNUvMsz825rEyHGeusBa+ps1Ib9d6c0lfIpPRFykOMk5gKyWiYcBbJMOZMUT8RoREMh2mcpIorD41FhZJBqAhDKjARikoVhUEciICy+Lw5r4no2KnXEK1tKWOtbduLR/e27d2PRLaets13LdMAnqPWE7cuv7rT1kG9e11hMX1ubtzXz+JQJ7u3L/ej7vFOmRXVqumavdZZE5cvJF+m5Td31ykyjWkuxeT5dagTV8BPrRG7V/+yY1LzGsbdOP/CHT6Cnb6LZJ9S/1xKcEipa/WOE9NNXS6lSWv38KYTHnjzpbrT85G31GEpbndX5wcypvSC/AwAAA==
"""
