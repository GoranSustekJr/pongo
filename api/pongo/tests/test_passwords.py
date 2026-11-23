import pytest

from library.auth import passwords


def test_a_password_checks_against_its_own_hash_only():
    stored = passwords.hash_password("correct horse")
    assert stored.startswith("scrypt$")
    assert passwords.verify_password("correct horse", stored)
    assert not passwords.verify_password("correct hose", stored)
    assert passwords.hash_password("correct horse") != stored  # salted


def test_broken_hashes_never_match():
    for stored in ("", "bcrypt$x", "scrypt$1$2$3$!!$!!", "scrypt$a$b$c$d$e"):
        assert not passwords.verify_password("anything", stored)


def test_usernames_are_lower_case_and_limited():
    assert passwords.normalize_username("  Goran.S@Example.com ") == "goran.s@example.com"
    for bad in ("", "ab", "-start", "has space", "x" * 65, "emoji🎵"):
        with pytest.raises(passwords.InvalidInput):
            passwords.normalize_username(bad)


def test_passwords_need_eight_characters():
    with pytest.raises(passwords.InvalidInput):
        passwords.check_password("short")
    assert passwords.check_password("long enough") == "long enough"
