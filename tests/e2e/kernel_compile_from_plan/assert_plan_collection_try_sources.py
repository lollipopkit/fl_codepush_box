import json


def assert_collection_try_sources(source_for):
    def require_source(name, type_args, required, params=None):
        source = source_for(name)
        source_json = json.dumps(source)
        params = params or ["ready", "extra", "tail"]
        if (
            source.get("async_future") is not True
            or source.get("body", {}).get("new_object", {}).get("type_args") != [type_args]
            or source.get("params") != params
            or any(item not in source_json for item in required)
        ):
            raise SystemExit(f"expected {name} collection try source, got {source}")

    require_source(
        "asyncAwaitConditionTryCatchDynamicRuntimeNames",
        "List<String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "extra"}',
            '"source": {"arg": "tail"}',
            "patched-await-condition-try-catch-list-caught-",
        ],
    )
    require_source(
        "asyncAwaitThenTryFinallyDynamicRuntimeNames",
        "List<String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"method": "add"',
            "patched-await-then-try-finally-list-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyRuntimeDynamicNames",
        "List<String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-condition-try-catch-finally-list-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchDynamicRuntimeLabels",
        "Map<String,String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"method": "get:entries"',
            '"spread": {"arg": "extra"}',
            "patched-await-condition-try-catch-map-caught-",
        ],
    )
    require_source(
        "asyncAwaitThenTryFinallyDynamicRuntimeLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"method": "[]="',
            "patched-await-then-try-finally-map-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyRuntimeDynamicLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-condition-try-catch-finally-map-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchDynamicRuntimeStaticSpreadNames",
        "List<String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "extra"}',
            "patched-await-condition-try-catch-list-static-tail-a",
            "patched-await-condition-try-catch-list-static-caught-",
        ],
    )
    require_source(
        "asyncAwaitThenTryFinallyRuntimeDynamicStaticSpreadNames",
        "List<String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-then-try-finally-list-static-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyDynamicRuntimeTailNames",
        "List<String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"source": {"arg": "tail"}',
            "patched-await-condition-try-catch-finally-list-tail-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchDynamicRuntimeStaticSpreadLabels",
        "Map<String,String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"method": "get:entries"',
            "patched-await-condition-try-catch-map-static-tail-a",
            "patched-await-condition-try-catch-map-static-caught-",
        ],
    )
    require_source(
        "asyncAwaitThenTryFinallyRuntimeDynamicStaticSpreadLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"method": "[]="',
            "patched-await-then-try-finally-map-static-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyDynamicRuntimeTailLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"method": "get:entries"',
            "patched-await-condition-try-catch-finally-map-tail-cleanup",
        ],
    )
    require_source(
        "asyncAwaitConditionTryCatchRuntimeDynamicRuntimeNames",
        "List<String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "middle"}',
            '"source": {"arg": "tail"}',
            "patched-await-condition-try-catch-list-rdr-caught-",
        ],
        ["ready", "extra", "middle", "tail"],
    )
    require_source(
        "asyncAwaitThenTryFinallyDynamicRuntimeDynamicNames",
        "List<String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-then-try-finally-list-drd-cleanup",
        ],
        ["ready", "extra", "middle", "tail"],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyRuntimeRuntimeDynamicNames",
        "List<String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-condition-try-catch-finally-list-rrd-cleanup",
        ],
        ["ready", "extra", "middle", "tail"],
    )
    require_source(
        "asyncAwaitConditionTryCatchRuntimeDynamicRuntimeLabels",
        "Map<String,String>",
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"spread": {"arg": "middle"}',
            '"method": "get:entries"',
            "patched-await-condition-try-catch-map-rdr-caught-",
        ],
        ["ready", "extra", "middle", "tail"],
    )
    require_source(
        "asyncAwaitThenTryFinallyDynamicRuntimeDynamicLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"name": "enabled"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-then-try-finally-map-drd-cleanup",
        ],
        ["ready", "extra", "middle", "tail"],
    )
    require_source(
        "asyncAwaitConditionTryCatchFinallyRuntimeRuntimeDynamicLabels",
        "Map<String,String>",
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"spread": {"arg": "tail"}',
            "patched-await-condition-try-catch-finally-map-rrd-cleanup",
        ],
        ["ready", "extra", "middle", "tail"],
    )
