import json


def assert_collection_try_await_sources(source_for):
    def require_source(name, type_args, params, required):
        source = source_for(name)
        source_json = json.dumps(source)
        if (
            source.get("async_future") is not True
            or source.get("body", {}).get("new_object", {}).get("type_args") != [type_args]
            or source.get("params") != params
            or any(item not in source_json for item in required)
        ):
            raise SystemExit(f"expected {name} collection try-await source, got {source}")

    require_source(
        "asyncCollectionTryCatchAwaitRecoveryNames",
        "List<String>",
        ["ready", "recovery", "extra"],
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"spread": {"arg": "extra"}',
            '"await": {"arg": "recovery"}',
            "patched-collection-try-catch-await-list-caught-",
        ],
    )
    require_source(
        "asyncCollectionTryFinallyAwaitCleanupNames",
        "List<String>",
        ["ready", "cleanup", "extra"],
        [
            '"try_finally"',
            '"await": {"arg": "ready"}',
            '"list_for_in"',
            '"await": {"arg": "cleanup"}',
            "patched-collection-try-finally-await-list-cleanup-",
        ],
    )
    require_source(
        "asyncCollectionTryCatchFinallyAwaitRecoveryNames",
        "List<String>",
        ["ready", "recovery", "cleanup", "extra"],
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"await": {"arg": "recovery"}',
            '"await": {"arg": "cleanup"}',
            "patched-collection-try-catch-finally-await-list-cleanup-",
        ],
    )
    require_source(
        "asyncCollectionTryCatchAwaitRecoveryLabels",
        "Map<String,String>",
        ["ready", "recovery", "extra"],
        [
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"spread": {"arg": "extra"}',
            '"await": {"arg": "recovery"}',
            "patched-collection-try-catch-await-map-caught-",
        ],
    )
    require_source(
        "asyncCollectionTryFinallyAwaitCleanupLabels",
        "Map<String,String>",
        ["ready", "cleanup", "extra"],
        [
            '"try_finally"',
            '"await": {"arg": "ready"}',
            '"map_for_in"',
            '"await": {"arg": "cleanup"}',
            "patched-collection-try-finally-await-map-cleanup-",
        ],
    )
    require_source(
        "asyncCollectionTryCatchFinallyAwaitRecoveryLabels",
        "Map<String,String>",
        ["ready", "recovery", "cleanup", "extra"],
        [
            '"try_finally"',
            '"try_catch"',
            '"await": {"arg": "ready"}',
            '"await": {"arg": "recovery"}',
            '"await": {"arg": "cleanup"}',
            "patched-collection-try-catch-finally-await-map-cleanup-",
        ],
    )
