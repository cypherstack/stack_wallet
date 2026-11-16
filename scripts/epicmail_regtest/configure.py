#!/usr/bin/env python3
"""Generate local-only Epic, Epic Wallet and Epicmail configurations."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def replace(text: str, key: str, value: str) -> str:
    pattern = rf"(?m)^(#\s*)?{re.escape(key)}\s*=.*$"
    updated, count = re.subn(pattern, f"{key} = {value}", text, count=1)
    if count != 1:
        raise SystemExit(f"generated config has no unique {key!r} setting")
    return updated


def node(args: argparse.Namespace) -> None:
    path = Path(args.path)
    text = path.read_text()
    values = {
        "db_root": json.dumps(str(Path(args.runtime) / "chain_data")),
        "api_http_addr": json.dumps("127.0.0.1:43413"),
        "chain_type": json.dumps("UserTesting"),
        "skip_sync_wait": "true",
        "run_tui": "false",
        # The pinned test-only patch maps this existing switch to Cuckatoo,
        # which is the proof type produced by the built-in usernet miner.
        "only_randomx": "true",
        "run_test_miner": "true",
        "host": json.dumps("127.0.0.1"),
        "port": "43414",
        "seeding_type": json.dumps("None"),
        "socks_proxy_addr": json.dumps(""),
        "log_to_file": "false",
    }
    for key, value in values.items():
        text = replace(text, key, value)
    if "peer_min_preferred_outbound_count" not in text:
        text, count = re.subn(
            r'(?m)^(seeding_type\s*=.*)$',
            r'\1\npeer_min_preferred_outbound_count = 0',
            text,
            count=1,
        )
        if count != 1:
            raise SystemExit("generated config has no unique seeding type")
    if args.fund:
        text = replace(
            text,
            "test_miner_wallet_url",
            json.dumps("http://127.0.0.1:43415"),
        )
    else:
        text, count = re.subn(
            r"(?m)^(#\s*)?test_miner_wallet_url\s*=.*$",
            '#test_miner_wallet_url = "http://127.0.0.1:43415"',
            text,
            count=1,
        )
        if count != 1:
            raise SystemExit("generated config has no unique test miner URL")
    path.write_text(text)


def wallet(args: argparse.Namespace) -> None:
    path = Path(args.path)
    text = path.read_text()
    values = {
        "chain_type": json.dumps("UserTesting"),
        "api_listen_interface": json.dumps("127.0.0.1"),
        "api_listen_port": str(args.api_port),
        "check_node_api_http_addr": json.dumps("http://127.0.0.1:43413"),
        "epicbox_domain": json.dumps("127.0.0.1"),
        "epicbox_port": str(args.relay_port),
        "epicbox_protocol_unsecure": str(args.relay_unsecure).lower(),
    }
    for key, value in values.items():
        text = replace(text, key, value)
    path.write_text(text)


def epicmail(args: argparse.Namespace) -> None:
    runtime = Path(args.runtime)
    store_path = json.dumps(str(runtime / "epicmail.db"))
    Path(args.path).write_text(
        f'''[server]
listen = "127.0.0.1:43420"
domain = "127.0.0.1"
port = 43420
aliases = []
landing_page = true

[store]
path = {store_path}

[limits]
shared_sources = ["127.0.0.1/32"]

[federation]
enabled = true
allow_private = true

[log]
level = "debug"
summary_interval_s = 10

[log.file]
enabled = false
'''
    )


def epicmail_mixed(args: argparse.Namespace) -> None:
    runtime = Path(args.runtime)
    store_path = json.dumps(str(runtime / "epicmail-mixed.db"))
    Path(args.path).write_text(
        f'''[server]
listen = "127.0.0.1:43422"
domain = "127.0.0.1"
port = 43420
aliases = []
landing_page = true

[store]
path = {store_path}

[limits]
shared_sources = ["127.0.0.1/32"]

[federation]
enabled = true
allow_private = true

[federation.peers]
"127.0.0.1:43421" = "ws://127.0.0.1:43421/"

[log]
level = "debug"
summary_interval_s = 10

[log.file]
enabled = false
'''
    )


def epicmail_cutover(args: argparse.Namespace) -> None:
    runtime = Path(args.runtime)
    store_path = json.dumps(str(runtime / "epicmail-cutover.db"))
    Path(args.path).write_text(
        f'''[server]
listen = "127.0.0.1:43421"
domain = "127.0.0.1"
port = 43421
aliases = []

[store]
path = {store_path}

[limits]
shared_sources = ["127.0.0.1/32"]

[federation]
enabled = true
allow_private = true

[federation.peers]
"127.0.0.1:43420" = "ws://127.0.0.1:43422/"

[log]
level = "debug"

[log.file]
enabled = false
'''
    )


def legacy(args: argparse.Namespace) -> None:
    Path(args.path).write_text(
        json.dumps(
            {
                "mongo_url": "mongodb://127.0.0.1:27019",
                "mongo_dbName": "epicbox_regtest",
                "mongo_collection_name": "slates",
                "mongo_cancelled_collection_name": "cancelled_slates",
                "epicbox_domain": "127.0.0.1",
                "epicbox_port": 43421,
                "local_epicbox_service_port": 43421,
                "path_to_epicboxlib_exec_file": str(
                    Path(args.source)
                    / "epicboxlib_source"
                    / "target"
                    / "release"
                    / "epicboxlib"
                ),
                "challenge_interval": 60000,
                "debug": False,
                "stats": True,
            },
            indent=2,
        )
        + "\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    subs = parser.add_subparsers(required=True)
    p = subs.add_parser("node")
    p.add_argument("path")
    p.add_argument("runtime")
    p.add_argument("--fund", action="store_true")
    p.set_defaults(func=node)
    p = subs.add_parser("wallet")
    p.add_argument("path")
    p.add_argument("--api-port", type=int, default=43415)
    p.add_argument("--relay-port", type=int, default=43420)
    p.add_argument(
        "--relay-unsecure",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    p.set_defaults(func=wallet)
    p = subs.add_parser("epicmail")
    p.add_argument("path")
    p.add_argument("runtime")
    p.set_defaults(func=epicmail)
    p = subs.add_parser("epicmail-mixed")
    p.add_argument("path")
    p.add_argument("runtime")
    p.set_defaults(func=epicmail_mixed)
    p = subs.add_parser("epicmail-cutover")
    p.add_argument("path")
    p.add_argument("runtime")
    p.set_defaults(func=epicmail_cutover)
    p = subs.add_parser("legacy")
    p.add_argument("path")
    p.add_argument("source")
    p.set_defaults(func=legacy)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
