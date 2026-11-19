from library import limits


def test_allows_up_to_the_limit_then_refuses(monkeypatch):
    now = [0.0]
    monkeypatch.setattr(limits.time, "monotonic", lambda: now[0])
    window = limits.SlidingWindow(limit=2, seconds=60)
    assert window.allow("ip") and window.allow("ip")
    assert not window.allow("ip")
    assert window.allow("other ip")
    now[0] = 61
    assert window.allow("ip")


def test_forgets_idle_keys_instead_of_growing(monkeypatch):
    now = [0.0]
    monkeypatch.setattr(limits.time, "monotonic", lambda: now[0])
    window = limits.SlidingWindow(limit=1, seconds=10, max_keys=3)
    for key in "abc":
        window.allow(key)
    now[0] = 11
    window.allow("d")
    assert len(window._events) == 1
    # Full of active keys: the oldest goes
    for key in "efg":
        window.allow(key)
    assert len(window._events) == 3


def test_stream_tokens_are_cut_out_of_the_access_log():
    import logging

    record = logging.LogRecord(
        "uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
        ("1.2.3.4", "GET", "/play_song/42?st=secret.token&x=1", "1.1", 200), None,
    )
    stream = logging.LogRecord(
        "uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
        ("1.2.3.4", "GET", "/stream/secret.token/42/index.m3u8", "1.1", 200), None,
    )
    hide = limits.HideStreamTokens()
    assert hide.filter(record) and hide.filter(stream)
    assert "secret" not in record.getMessage() and "/play_song/42?st=***&x=1" in record.getMessage()
    assert "secret" not in stream.getMessage() and "/stream/***/42/index.m3u8" in stream.getMessage()
