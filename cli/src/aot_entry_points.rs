//! ADR-#2: derive the set of functions that survive AOT compilation (real entry
//! points) so the patch-time `call_original` gate can reject targets that were
//! tree-shaken/inlined out of the release snapshot.
//!
//! Source of truth is `gen_snapshot --print_instructions_sizes_to`, which emits
//! every function compiled into the AOT snapshot as
//! `{"l":library,"c":class,"n":"[Optimized] member","s":size}`. We normalize each
//! entry to the same id shape the Dart compiler uses for `call_original`/`call`
//! targets: `libraryUri::member` (top-level) or `libraryUri::class:Class.member`.

use fcb_core::{err, Result};
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::process::Command as ProcessCommand;

#[derive(serde::Deserialize)]
struct SizeEntry {
    #[serde(default)]
    l: Option<String>,
    #[serde(default)]
    c: Option<String>,
    n: String,
}

/// Strip Dart's private mangling suffix `@<digits>` wherever it appears, e.g.
/// `_refreshState@337133756` -> `_refreshState`. The compiler's target naming
/// uses the unmangled member name.
fn strip_mangle(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    let bytes = name.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'@' && i + 1 < bytes.len() && bytes[i + 1].is_ascii_digit() {
            i += 1;
            while i < bytes.len() && bytes[i].is_ascii_digit() {
                i += 1;
            }
        } else {
            out.push(bytes[i] as char);
            i += 1;
        }
    }
    out
}

/// Normalize one gen_snapshot size entry to a `call_original`-style target id, or
/// `None` for entries that are not addressable Dart functions (stubs, tear-offs,
/// anonymous closures, allocation/type stubs).
fn normalize_entry(entry: &SizeEntry) -> Option<String> {
    let library = entry.l.as_deref()?;
    if library.is_empty() {
        return None;
    }
    // Strip a leading "[Optimized] " / "[Unoptimized] " / "[Stub] " tag.
    let name = match (entry.n.starts_with('['), entry.n.find("] ")) {
        (true, Some(idx)) => &entry.n[idx + 2..],
        _ => entry.n.as_str(),
    };
    // Non-callable / non-addressable entries.
    if name.starts_with("[tear-off]")
        || name.starts_with("[tear-off-extractor]")
        || name.contains("<anonymous closure")
        || name.contains("<anonymous")
        || name.starts_with("Allocate ")
        || name.starts_with("Type ")
        || name.starts_with("dyn:")
    {
        return None;
    }
    // Generative/factory constructor: "new Class.ctor" -> class:Class.ctor
    if let Some(rest) = name.strip_prefix("new ") {
        let rest = strip_mangle(rest);
        return Some(format!("{library}::class:{rest}"));
    }
    let member = strip_mangle(name);
    match entry.c.as_deref() {
        Some(class) if !class.is_empty() => {
            Some(format!("{library}::class:{}.{member}", strip_mangle(class)))
        }
        _ => Some(format!("{library}::{member}")),
    }
}

/// Parse a gen_snapshot instruction-sizes JSON document into the set of surviving
/// AOT entry-point ids.
pub(crate) fn parse_gen_snapshot_sizes(json: &[u8]) -> Result<BTreeSet<String>> {
    let entries: Vec<SizeEntry> = serde_json::from_slice(json)
        .map_err(|e| err(format!("invalid gen_snapshot sizes: {e}")))?;
    Ok(entries.iter().filter_map(normalize_entry).collect())
}

/// Best-effort location of the `gen_snapshot` binary inside the Flutter SDK
/// engine artifact cache for the given platform/arch. Returns `None` when no
/// candidate exists (callers then skip AOT-presence generation).
pub(crate) fn gen_snapshot_path(
    flutter_root: &Path,
    platform: &str,
    arch: &str,
) -> Option<PathBuf> {
    let engine = flutter_root.join("bin/cache/artifacts/engine");
    let host = if cfg!(target_os = "macos") {
        "darwin-x64"
    } else {
        "linux-x64"
    };
    let candidates: Vec<PathBuf> = match platform {
        "android" => {
            let dir = match arch {
                "arm64-v8a" => "android-arm64-release",
                "armeabi-v7a" => "android-arm-release",
                "x86_64" => "android-x64-release",
                _ => return None,
            };
            vec![engine.join(dir).join(host).join("gen_snapshot")]
        }
        "ios" => vec![
            engine.join("ios-release/gen_snapshot_arm64"),
            engine.join("ios/gen_snapshot_arm64"),
        ],
        _ => return None,
    };
    candidates.into_iter().find(|path| path.exists())
}

/// Run gen_snapshot over `dill` to obtain the surviving AOT entry-point set.
pub(crate) fn extract_aot_entry_points(
    gen_snapshot: &Path,
    dill: &Path,
) -> Result<BTreeSet<String>> {
    let temp = std::env::temp_dir().join(format!("fcb-aot-{}", uuid::Uuid::new_v4()));
    std::fs::create_dir_all(&temp)?;
    let sizes = temp.join("instructions_sizes.json");
    let elf = temp.join("app.so");
    let output = ProcessCommand::new(gen_snapshot)
        .arg("--deterministic")
        .arg("--snapshot_kind=app-aot-elf")
        .arg(format!("--elf={}", elf.display()))
        .arg(format!("--print_instructions_sizes_to={}", sizes.display()))
        .arg(dill)
        .output()?;
    if !output.status.success() {
        let _ = std::fs::remove_dir_all(&temp);
        return Err(err(format!(
            "gen_snapshot failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }
    let json = std::fs::read(&sizes)?;
    let result = parse_gen_snapshot_sizes(&json);
    let _ = std::fs::remove_dir_all(&temp);
    result
}

/// Generate `aot_entry_points.json` in the release cache. Best-effort: if
/// gen_snapshot or the dill cannot be located, returns `Ok(None)` so the release
/// still succeeds (the patch-time gate then warns and skips).
pub(crate) fn generate_aot_entry_points(
    release_dir: &Path,
    flutter_root: &Path,
    dill: Option<&Path>,
    platform: &str,
    arch: &str,
) -> Result<Option<usize>> {
    let (Some(gen_snapshot), Some(dill)) = (gen_snapshot_path(flutter_root, platform, arch), dill)
    else {
        return Ok(None);
    };
    let entry_points = extract_aot_entry_points(&gen_snapshot, dill)?;
    let payload = serde_json::json!({
        "schema_version": 1,
        "platform": platform,
        "arch": arch,
        "function_ids": entry_points.iter().collect::<Vec<_>>(),
    });
    std::fs::write(
        release_dir.join("aot_entry_points.json"),
        serde_json::to_vec_pretty(&payload)?,
    )?;
    Ok(Some(entry_points.len()))
}

#[cfg(test)]
mod tests {
    use super::{normalize_entry, parse_gen_snapshot_sizes, strip_mangle, SizeEntry};

    fn entry(l: &str, c: &str, n: &str) -> SizeEntry {
        SizeEntry {
            l: Some(l.to_string()),
            c: Some(c.to_string()),
            n: n.to_string(),
        }
    }

    #[test]
    fn strips_private_mangling() {
        assert_eq!(strip_mangle("_refreshState@337133756"), "_refreshState");
        assert_eq!(strip_mangle("plain"), "plain");
        assert_eq!(strip_mangle("_GrowableList@0150898"), "_GrowableList");
    }

    #[test]
    fn normalizes_top_level_and_method_like_the_compiler() {
        // Top-level public function (c empty) -> libraryUri::member
        assert_eq!(
            normalize_entry(&entry(
                "package:fcb_counter_app/pricing_source.dart",
                "",
                "[Optimized] widgetTreeLabel",
            )),
            Some("package:fcb_counter_app/pricing_source.dart::widgetTreeLabel".to_string())
        );
        // Instance method -> libraryUri::class:Class.member (mangling stripped)
        assert_eq!(
            normalize_entry(&entry(
                "package:fcb_counter_app/main.dart",
                "_CounterAppState",
                "[Optimized] _refreshState@337133756",
            )),
            Some(
                "package:fcb_counter_app/main.dart::class:_CounterAppState._refreshState"
                    .to_string()
            )
        );
        // Constructor.
        assert_eq!(
            normalize_entry(&entry(
                "package:fcb_counter_app/pricing_source.dart",
                "PricingOffer",
                "[Optimized] new PricingOffer.",
            )),
            Some("package:fcb_counter_app/pricing_source.dart::class:PricingOffer.".to_string())
        );
    }

    #[test]
    fn skips_non_callable_entries() {
        assert_eq!(
            normalize_entry(&entry(
                "package:app/main.dart",
                "",
                "[Optimized] [tear-off] main"
            )),
            None
        );
        assert_eq!(
            normalize_entry(&entry(
                "package:app/main.dart",
                "S",
                "[Optimized] _run@1.<anonymous closure @6844>",
            )),
            None
        );
        // Stub with no library is dropped.
        assert_eq!(
            normalize_entry(&SizeEntry {
                l: None,
                c: None,
                n: "[Stub] Type Test".to_string(),
            }),
            None
        );
    }

    // Real end-to-end check against the vendored gen_snapshot + a counter_app
    // dill. Machine-specific (needs the vendor checkout), so #[ignore]d out of CI.
    // Run with: cargo test -p fcb -- --ignored aot_real
    #[test]
    #[ignore]
    fn aot_real_extraction_includes_counter_app_call_targets() {
        use std::path::{Path, PathBuf};
        let repo = Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap();
        let flutter_root = repo.join("vendor/flutter");
        let gen_snapshot = super::gen_snapshot_path(&flutter_root, "android", "arm64-v8a")
            .expect("vendored gen_snapshot present");

        // Pick the largest app.dill under counter_app's flutter_build cache.
        let build_dir = repo.join("examples/counter_app/.dart_tool/flutter_build");
        let mut dills: Vec<PathBuf> = std::fs::read_dir(&build_dir)
            .expect("flutter_build dir")
            .filter_map(|e| e.ok().map(|e| e.path().join("app.dill")))
            .filter(|p| p.exists())
            .collect();
        dills.sort_by_key(|p| std::fs::metadata(p).map(|m| m.len()).unwrap_or(0));
        let dill = dills.last().expect("an app.dill exists");

        let set = super::extract_aot_entry_points(&gen_snapshot, dill).expect("extract");
        assert!(
            set.len() > 1000,
            "expected a populated AOT set, got {}",
            set.len()
        );
        for target in [
            "package:fcb_counter_app/pricing_source.dart::widgetTreeLabel",
            "package:fcb_counter_app/pricing_source.dart::statusLabel",
        ] {
            assert!(set.contains(target), "missing surviving target: {target}");
        }
        // A clearly tree-shaken/non-existent target must be absent (gate fires).
        assert!(!set.contains("package:fcb_counter_app/pricing_source.dart::neverDefinedFn"));
    }

    #[test]
    fn parses_array_into_target_id_set() {
        let json = br#"[
            {"l":"package:app/main.dart","c":"","n":"[Optimized] helper","s":10},
            {"l":"package:app/main.dart","c":"Foo","n":"[Optimized] bar@7","s":20},
            {"l":"package:app/main.dart","c":"","n":"[Optimized] [tear-off] main","s":5}
        ]"#;
        let set = parse_gen_snapshot_sizes(json).expect("parse");
        assert!(set.contains("package:app/main.dart::helper"));
        assert!(set.contains("package:app/main.dart::class:Foo.bar"));
        assert_eq!(set.len(), 2);
    }
}
