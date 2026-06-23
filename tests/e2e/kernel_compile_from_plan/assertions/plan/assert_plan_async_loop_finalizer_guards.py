import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_finalizer_guard(
    name,
    constants,
    awaits,
    *,
    has_catch=False,
    min_conditionals=0,
    requires_list_add_all=False,
    requires_map_add_all=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or '"while_loop"' not in source_json
        or '"try_finally"' not in source_json
        or '"break_body"' not in source_json
        or '"continue_condition"' not in source_json
        or '"break_condition"' not in source_json
        or source_json.count('"await"') < len(awaits)
        or source_json.count('"conditional"') < min_conditionals
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_list_add_all and '"list_add_all"' not in source_json)
        or (requires_map_add_all and '"map_add_all"' not in source_json)
        or any(f'"await": {{"arg": "{arg}"}}' not in source_json for arg in awaits)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async loop finalizer guard source, got {function}")


assert_finalizer_guard(
    "asyncWhileTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-finalizer-guard",
        "-body-",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-await-condition-finalizer-guard",
        "-body",
        "-finally-",
    ],
    ["keepGoing", "skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncWhileNestedTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-nested-finalizer-guard",
        "-premium-",
        "-basic-",
        "-finally-",
    ],
    ["skip", "stop", "ready", "cleanup"],
    min_conditionals=1,
)
assert_finalizer_guard(
    "asyncWhileTryCatchFinallyAwaitGuardContinueBreak",
    [
        "patched-while-catch-finalizer-guard",
        "patched-while-catch-finalizer-guard-error-",
        "-caught-",
        "-finally-",
    ],
    ["skip", "stop", "fail", "cleanup"],
    has_catch=True,
)
assert_finalizer_guard(
    "asyncDoWhileTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-finalizer-guard",
        "-body-",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncDoWhileAwaitConditionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-await-condition-finalizer-guard",
        "-body",
        "-finally-",
    ],
    ["keepGoing", "skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncDoWhileNestedTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-nested-finalizer-guard",
        "-premium-",
        "-basic-",
        "-finally-",
    ],
    ["skip", "stop", "ready", "cleanup"],
    min_conditionals=1,
)
assert_finalizer_guard(
    "asyncDoWhileTryCatchFinallyAwaitGuardContinueBreak",
    [
        "patched-do-catch-finalizer-guard",
        "patched-do-catch-finalizer-guard-error-",
        "-caught-",
        "-finally-",
    ],
    ["skip", "stop", "fail", "cleanup"],
    has_catch=True,
)
assert_finalizer_guard(
    "asyncWhileSwitchTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-switch-finalizer-guard",
        "patched-while-switch-finalizer-gold",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncDoWhileSwitchTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-switch-finalizer-guard",
        "patched-do-switch-finalizer-gold",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
)
assert_finalizer_guard(
    "asyncWhileSwitchOrPatternTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-switch-or-finalizer-guard",
        "patched-while-switch-or-finalizer-premium",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
    min_conditionals=1,
)
assert_finalizer_guard(
    "asyncDoWhileSwitchOrPatternTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-switch-or-finalizer-guard",
        "patched-do-switch-or-finalizer-premium",
        "-finally-",
    ],
    ["skip", "stop", "cleanup"],
    min_conditionals=1,
)
assert_finalizer_guard(
    "asyncWhileCollectionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-collection-finalizer-head",
        "patched-while-collection-finalizer-body-",
        "patched-while-collection-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileCollectionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-collection-finalizer-head",
        "patched-do-collection-finalizer-body-",
        "patched-do-collection-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileMapCollectionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-map-finalizer-head",
        "patched-while-map-finalizer-body-",
        "patched-while-map-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileMapCollectionTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-map-finalizer-head",
        "patched-do-map-finalizer-body-",
        "patched-do-map-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileCollectionSwitchForTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-collection-switch-finalizer-head",
        "patched-while-collection-switch-finalizer-premium",
        "patched-while-collection-switch-finalizer-extra-",
        "patched-while-collection-switch-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileCollectionSwitchForTryFinallyAwaitGuardContinueBreak",
    [
        "patched-do-collection-switch-finalizer-head",
        "patched-do-collection-switch-finalizer-premium",
        "patched-do-collection-switch-finalizer-extra-",
        "patched-do-collection-switch-finalizer-cleanup-",
    ],
    ["skip", "stop", "cleanup"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileMapSwitchForTryCatchFinallyAwaitGuardContinueBreak",
    [
        "patched-while-map-switch-finalizer-head",
        "patched-while-map-switch-finalizer-premium",
        "patched-while-map-switch-finalizer-extra-",
        "patched-while-map-switch-finalizer-caught-",
        "patched-while-map-switch-finalizer-cleanup-",
    ],
    ["skip", "stop", "fail", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileMapSwitchForTryCatchFinallyAwaitGuardContinueBreak",
    [
        "patched-do-map-switch-finalizer-head",
        "patched-do-map-switch-finalizer-premium",
        "patched-do-map-switch-finalizer-extra-",
        "patched-do-map-switch-finalizer-caught-",
        "patched-do-map-switch-finalizer-cleanup-",
    ],
    ["skip", "stop", "fail", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionCollectionSwitchTryFinallyAwaitGuardContinueBreak",
    [
        "patched-while-await-condition-collection-switch-finalizer-head",
        "patched-while-await-condition-collection-switch-finalizer-premium",
        "patched-while-await-condition-collection-switch-finalizer-extra-",
        "patched-while-await-condition-collection-switch-finalizer-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "cleanup"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileAwaitConditionMapSwitchForTryCatchFinallyAwaitGuardContinueBreak",
    [
        "patched-do-await-condition-map-switch-finalizer-head",
        "patched-do-await-condition-map-switch-finalizer-premium",
        "patched-do-await-condition-map-switch-finalizer-extra-",
        "patched-do-await-condition-map-switch-finalizer-caught-",
        "patched-do-await-condition-map-switch-finalizer-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "fail", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileNestedCollectionTryFinallyAwaitGuard",
    [
        "patched-while-nested-collection-finalizer-head",
        "patched-while-nested-collection-finalizer-premium-",
        "patched-while-nested-collection-finalizer-extra-",
        "patched-while-nested-collection-finalizer-cleanup-",
    ],
    ["skip", "stop", "ready", "cleanup"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileNestedMapTryCatchFinallyAwaitGuard",
    [
        "patched-do-nested-map-finalizer-head",
        "patched-do-nested-map-finalizer-premium-",
        "patched-do-nested-map-finalizer-extra-",
        "patched-do-nested-map-finalizer-caught-",
        "patched-do-nested-map-finalizer-cleanup-",
    ],
    ["skip", "stop", "fail", "ready", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionNestedCollectionTryCatchFinallyGuard",
    [
        "patched-while-await-condition-nested-collection-finalizer-head",
        "patched-while-await-condition-nested-collection-premium-",
        "patched-while-await-condition-nested-collection-extra-",
        "patched-while-await-condition-nested-collection-caught-",
        "patched-while-await-condition-nested-collection-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "fail", "ready", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncForAwaitConditionSwitchMapTryFinallyAwaitGuard",
    [
        "patched-for-await-condition-switch-map-finalizer-head",
        "patched-for-await-condition-switch-map-premium-",
        "patched-for-await-condition-switch-map-extra-",
        "patched-for-await-condition-switch-map-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "cleanup"],
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileMultiAwaitUpdateCollectionTryCatchFinallyGuard",
    [
        "patched-while-multi-await-update-collection-finalizer-head",
        "patched-while-multi-await-update-collection-body-",
        "patched-while-multi-await-update-collection-extra-",
        "patched-while-multi-await-update-collection-caught-",
        "patched-while-multi-await-update-collection-cleanup-",
    ],
    ["skip", "stop", "fail", "cleanup", "nextI", "nextJ"],
    has_catch=True,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileSwitchMapNestedTryCatchFinallyGuard",
    [
        "patched-do-switch-map-nested-finalizer-head",
        "patched-do-switch-map-nested-finalizer-premium-",
        "patched-do-switch-map-nested-finalizer-extra-",
        "patched-do-switch-map-nested-finalizer-caught-",
        "patched-do-switch-map-nested-finalizer-cleanup-",
    ],
    ["skip", "stop", "fail", "ready", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileSwitchCollectionFinallyNestedCleanupGuard",
    [
        "patched-while-switch-collection-nested-cleanup-head",
        "patched-while-switch-collection-nested-cleanup-premium",
        "patched-while-switch-collection-nested-cleanup-extra-",
        "patched-while-switch-collection-nested-cleanup-",
    ],
    ["skip", "stop", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionMapTryCatchFinallyDoubleCleanupGuard",
    [
        "patched-while-await-condition-map-double-cleanup-head",
        "patched-while-await-condition-map-double-cleanup-extra-",
        "patched-while-await-condition-map-double-cleanup-caught-",
        "patched-while-await-condition-map-double-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "fail", "recovery", "cleanup", "cleanupTail"],
    has_catch=True,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionSwitchCollectionDoubleCleanupGuard",
    [
        "patched-while-await-condition-switch-collection-double-cleanup-head",
        "patched-while-await-condition-switch-collection-double-cleanup-premium",
        "patched-while-await-condition-switch-collection-double-cleanup-extra-",
        "patched-while-await-condition-switch-collection-double-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileAwaitConditionMapTryCatchDoubleCleanupGuard",
    [
        "patched-do-await-condition-map-double-cleanup-head",
        "patched-do-await-condition-map-double-cleanup-extra-",
        "patched-do-await-condition-map-double-cleanup-caught-",
        "patched-do-await-condition-map-double-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "fail", "recovery", "cleanup", "cleanupTail"],
    has_catch=True,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileNestedSwitchCollectionTryCatchFinallyGuard",
    [
        "patched-while-nested-switch-collection-finalizer-head",
        "patched-while-nested-switch-collection-finalizer-premium-",
        "patched-while-nested-switch-collection-finalizer-extra-",
        "patched-while-nested-switch-collection-finalizer-caught-",
        "patched-while-nested-switch-collection-finalizer-cleanup-",
    ],
    ["skip", "stop", "fail", "ready", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileNestedSwitchMapTryFinallyDoubleCleanupGuard",
    [
        "patched-do-nested-switch-map-double-cleanup-head",
        "patched-do-nested-switch-map-double-cleanup-premium-",
        "patched-do-nested-switch-map-double-cleanup-extra-",
        "patched-do-nested-switch-map-double-cleanup-",
    ],
    ["skip", "stop", "ready", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncForAwaitConditionCollectionTryFinallyDoubleCleanupGuard",
    [
        "patched-for-await-condition-collection-double-cleanup-head",
        "patched-for-await-condition-collection-double-cleanup-body-",
        "patched-for-await-condition-collection-double-cleanup-extra-",
        "patched-for-await-condition-collection-double-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "cleanup", "cleanupTail"],
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileRuntimeMapTryCatchFinallyRecoveryCleanupGuard",
    [
        "patched-while-runtime-map-recovery-cleanup-head",
        "patched-while-runtime-map-recovery-cleanup-extra-",
        "patched-while-runtime-map-recovery-cleanup-caught-",
        "patched-while-runtime-map-recovery-cleanup-",
    ],
    ["skip", "stop", "fail", "recovery", "cleanup"],
    has_catch=True,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileAwaitConditionMapTryCatchFinallyRecoveryCleanupGuard",
    [
        "patched-while-await-condition-map-recovery-cleanup-head",
        "patched-while-await-condition-map-recovery-cleanup-extra-",
        "patched-while-await-condition-map-recovery-cleanup-caught-",
        "patched-while-await-condition-map-recovery-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "fail", "recovery", "cleanup"],
    has_catch=True,
    requires_map_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileSwitchCollectionTryCatchFinallyRecoveryGuard",
    [
        "patched-do-switch-collection-recovery-head",
        "patched-do-switch-collection-recovery-premium",
        "patched-do-switch-collection-recovery-extra-",
        "patched-do-switch-collection-recovery-caught-",
        "patched-do-switch-collection-recovery-cleanup-",
    ],
    ["skip", "stop", "fail", "recovery", "cleanup"],
    has_catch=True,
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileNestedListTryFinallyDoubleCleanupGuard",
    [
        "patched-while-nested-list-double-cleanup-head",
        "patched-while-nested-list-double-cleanup-premium-",
        "patched-while-nested-list-double-cleanup-extra-",
        "patched-while-nested-list-double-cleanup-",
    ],
    ["skip", "stop", "ready", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncForSwitchCollectionTryFinallyDoubleCleanupGuard",
    [
        "patched-for-switch-collection-double-cleanup-head",
        "patched-for-switch-collection-double-cleanup-premium",
        "patched-for-switch-collection-double-cleanup-extra-",
        "patched-for-switch-collection-double-cleanup-",
    ],
    ["skip", "stop", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncDoWhileAwaitConditionSwitchCollectionTryFinallyDoubleCleanupGuard",
    [
        "patched-do-await-condition-switch-collection-double-cleanup-head",
        "patched-do-await-condition-switch-collection-double-cleanup-premium",
        "patched-do-await-condition-switch-collection-double-cleanup-extra-",
        "patched-do-await-condition-switch-collection-double-cleanup-",
    ],
    ["keepGoing", "skip", "stop", "cleanup", "cleanupTail"],
    min_conditionals=1,
    requires_list_add_all=True,
)
assert_finalizer_guard(
    "asyncWhileMapSwitchTryCatchFinallyRecoveryDoubleCleanupGuard",
    [
        "patched-while-map-switch-recovery-double-cleanup-head",
        "patched-while-map-switch-recovery-double-cleanup-premium",
        "patched-while-map-switch-recovery-double-cleanup-extra-",
        "patched-while-map-switch-recovery-double-cleanup-caught-",
        "patched-while-map-switch-recovery-double-cleanup-",
    ],
    ["skip", "stop", "fail", "recovery", "cleanup", "cleanupTail"],
    has_catch=True,
    min_conditionals=1,
    requires_map_add_all=True,
)
