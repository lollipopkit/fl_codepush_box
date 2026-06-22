def assert_core_object_sources(source_for):
    async_make_user_source = source_for("asyncMakeUser")
    async_make_user_object = async_make_user_source.get("body", {}).get("new_object", {})
    async_make_user_arg = async_make_user_object.get("args", [{}])[0].get("new_object", {})
    if (
        async_make_user_source.get("async_future") is not True
        or async_make_user_object.get("type_args") != ["User"]
        or not async_make_user_arg.get("constructor", "").endswith("::class:User.")
        or async_make_user_arg.get("args") != [
            {"string": "patched-async"},
            {"string": "patched-async-label"},
        ]
    ):
        raise SystemExit(f"expected asyncMakeUser async new_object source, got {async_make_user_source}")

    async_await_user_source = source_for("asyncAwaitThenMakeUser")
    async_await_user_object = async_await_user_source.get("body", {}).get("new_object", {})
    async_await_user_let = async_await_user_object.get("args", [{}])[0].get("let", {})
    async_await_user_locals = async_await_user_let.get("locals", [])
    async_await_user_inner = async_await_user_let.get("body", {}).get("new_object", {})
    if (
        async_await_user_source.get("async_future") is not True
        or async_await_user_object.get("type_args") != ["User"]
        or async_await_user_source.get("params") != ["ready"]
        or len(async_await_user_locals) != 1
        or async_await_user_locals[0].get("name") != "label"
        or async_await_user_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or not async_await_user_inner.get("constructor", "").endswith("::class:User.")
        or async_await_user_inner.get("args") != [
            {"string": "patched-await-user"},
            {"let_local": 0},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenMakeUser await/positional new_object source, "
            f"got {async_await_user_source}"
        )

    async_make_config_source = source_for("asyncMakeConfig")
    async_make_config_object = async_make_config_source.get("body", {}).get("new_object", {})
    async_make_config_arg = async_make_config_object.get("args", [{}])[0].get("new_object", {})
    if (
        async_make_config_source.get("async_future") is not True
        or async_make_config_object.get("type_args") != ["Config"]
        or not async_make_config_arg.get("constructor", "").endswith("::class:Config.")
        or async_make_config_arg.get("named_args") != [
            {"name": "name", "value": {"string": "patched-async"}},
            {"name": "label", "value": {"string": "patched-async-label"}},
        ]
    ):
        raise SystemExit(f"expected asyncMakeConfig async named new_object source, got {async_make_config_source}")

    async_await_config_source = source_for("asyncAwaitThenMakeConfig")
    async_await_config_object = async_await_config_source.get("body", {}).get("new_object", {})
    async_await_config_let = async_await_config_object.get("args", [{}])[0].get("let", {})
    async_await_config_locals = async_await_config_let.get("locals", [])
    async_await_config_inner = async_await_config_let.get("body", {}).get("new_object", {})
    if (
        async_await_config_source.get("async_future") is not True
        or async_await_config_object.get("type_args") != ["Config"]
        or async_await_config_source.get("params") != ["ready"]
        or len(async_await_config_locals) != 1
        or async_await_config_locals[0].get("name") != "label"
        or async_await_config_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or not async_await_config_inner.get("constructor", "").endswith("::class:Config.")
        or async_await_config_inner.get("named_args") != [
            {"name": "name", "value": {"string": "patched-await-config"}},
            {"name": "label", "value": {"let_local": 0}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenMakeConfig await/named new_object source, "
            f"got {async_await_config_source}"
        )

    async_make_box_source = source_for("asyncMakeStringBox")
    async_make_box_object = async_make_box_source.get("body", {}).get("new_object", {})
    async_make_box_arg = async_make_box_object.get("args", [{}])[0].get("new_object", {})
    if (
        async_make_box_source.get("async_future") is not True
        or async_make_box_object.get("type_args") != ["Box<String>"]
        or not async_make_box_arg.get("constructor", "").endswith("::class:Box.")
        or async_make_box_arg.get("type_args") != ["String"]
        or async_make_box_arg.get("args") != [{"string": "patched-async-box"}]
    ):
        raise SystemExit(f"expected asyncMakeStringBox async generic new_object source, got {async_make_box_source}")

    async_await_box_source = source_for("asyncAwaitThenMakeStringBox")
    async_await_box_object = async_await_box_source.get("body", {}).get("new_object", {})
    async_await_box_let = async_await_box_object.get("args", [{}])[0].get("let", {})
    async_await_box_locals = async_await_box_let.get("locals", [])
    async_await_box_inner = async_await_box_let.get("body", {}).get("new_object", {})
    async_await_box_concat = async_await_box_inner.get("args", [{}])[0].get("concat", [])
    if (
        async_await_box_source.get("async_future") is not True
        or async_await_box_object.get("type_args") != ["Box<String>"]
        or async_await_box_source.get("params") != ["ready"]
        or len(async_await_box_locals) != 1
        or async_await_box_locals[0].get("name") != "value"
        or async_await_box_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or not async_await_box_inner.get("constructor", "").endswith("::class:Box.")
        or async_await_box_inner.get("type_args") != ["String"]
        or async_await_box_concat != [{"string": "patched-await-box:"}, {"let_local": 0}]
    ):
        raise SystemExit(f"expected asyncAwaitThenMakeStringBox await/generic new_object source, got {async_await_box_source}")
