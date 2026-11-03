from library.auth import tokens


def test_stream_token_is_stable_and_bound_to_the_device():
    first = tokens.create_stream_token("user", "phone")
    assert first == tokens.create_stream_token("user", "phone")
    assert first != tokens.create_stream_token("user", "tablet")


def test_access_and_refresh_tokens_are_not_interchangeable():
    access = tokens.create_access_token("user", "a@b.c", "phone")
    refresh = tokens.create_refresh_token("user", "a@b.c", "phone")
    assert tokens.decode(access, "at+JWT").uid == "user"
    assert tokens.decode(refresh, "rt+JWT").device_id == "phone"
    assert tokens.decode(access, "rt+JWT") is None
    assert tokens.decode(refresh, "at+JWT") is None
