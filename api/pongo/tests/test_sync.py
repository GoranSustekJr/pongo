import time
from datetime import timedelta

import pytest
from fastapi import HTTPException

from library.routes import sync


def _change(**overrides):
    return {"kind": "favourite", "key": "111", "data": {"title": "A"},
            "changed_at": int(time.time() * 1000), **overrides}


def test_a_change_is_parsed():
    kind, key, data, _ = sync._parse_change(_change())
    assert (kind, key, data) == ("favourite", "111", '{"title": "A"}')


def test_a_deletion_has_no_data():
    assert sync._parse_change(_change(data=None))[2] is None


@pytest.mark.parametrize("bad", [
    {"kind": "evil"}, {"key": ""}, {"key": "k" * 201}, {"key": 5},
    {"changed_at": "soon"}, {"changed_at": None}, {"changed_at": 10**30},
])
def test_bad_changes_are_refused(bad):
    with pytest.raises(HTTPException):
        sync._parse_change(_change(**bad))


def test_a_huge_item_is_refused():
    with pytest.raises(HTTPException) as error:
        sync._parse_change(_change(data={"cover": "a" * sync.MAX_ITEM_BYTES}))
    assert error.value.status_code == 413


def test_a_clock_far_ahead_cannot_win_for_long():
    far_ahead = int((time.time() + 86_400) * 1000)
    changed_at = sync._parse_change(_change(changed_at=far_ahead))[3]
    assert changed_at.timestamp() - time.time() <= sync.MAX_CLOCK_AHEAD / timedelta(seconds=1) + 1
