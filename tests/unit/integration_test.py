from __future__ import annotations

import re
from collections.abc import Sequence
from pathlib import Path

import pytest
from ruamel.yaml.main import YAML

from rflx.error import RecordFluxError
from rflx.identifier import ID
from rflx.integration import Integration


@pytest.mark.parametrize(
    ("rfi_content", "match_error"),
    [
        ("garbage", "expected dict not str"),
        ("Session: garbage", "Session.*value is not a valid dict"),
        ("{}", "Session.*field required"),
        (
            """Session:
                Session: 1
          """,
            "value is not a valid dict",
        ),
        (
            """Session:
                Session: {}
          """,
            "Buffer_Size.*field required",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: -1024
          """,
            "ensure this value is greater than 0",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: Hello
                        Global:
                            Msg: 2048
          """,
            "Default.*value is not a valid integer",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: 1024
                        Global:
                            Msg: Hello
          """,
            "Msg.*value is not a valid integer",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: 1024
                        Global:
                            Msg: -10
          """,
            "ensure this value is greater than 0",
        ),
        (
            """Session:
                Session:
                    Buffer_Size: 2
          """,
            "Buffer_Size.*value is not a valid dict",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: 1024
                        Global:
                            Msg: 2048
                        Local:
                            Next:
                                Msg2: -10
          """,
            "ensure this value is greater than 0",
        ),
        (
            """Session:
                Session:
                    Buffer_Size:
                        Default: 1024
                    Other: 1
          """,
            "Other.*extra fields not permitted",
        ),
    ],
)
def test_rfi_add_integration(rfi_content: str, match_error: str) -> None:
    # pydantic messages end with the type of the error in parentheses.
    regex = re.compile(
        (
            "^test.rfi:0:0: parser: error: 1 validation error for "
            rf"IntegrationFile.*{match_error} \([^()]*\)$"
        ),
        re.DOTALL,
    )
    yaml = YAML()
    content = yaml.load(rfi_content)
    error = RecordFluxError()
    integration = Integration()
    integration._add_integration_object(Path("test.rfi"), content, error)  # noqa: SLF001
    with pytest.raises(RecordFluxError, match=regex):
        error.propagate()


def test_rfi_get_size() -> None:
    integration = Integration()
    session_object = {
        "Session": {
            "S": {
                "Buffer_Size": {
                    "Default": 1024,
                    "Global": {
                        "Y": 2048,
                        "Z": 512,
                    },
                    "Local": {
                        "S": {
                            "Y": 8192,
                        }
                    },
                }
            }
        }
    }
    error = RecordFluxError()

    integration._add_integration_object(Path("p.rfi"), session_object, error)  # noqa: SLF001
    error.propagate()
    assert integration.get_size(ID("P::S"), None, None) == 1024
    assert integration.get_size(ID("P::S"), ID("X"), ID("S")) == 1024
    assert integration.get_size(ID("P::S"), ID("X"), ID("S")) == 1024
    assert integration.get_size(ID("P::S"), ID("X"), None) == 1024
    assert integration.get_size(ID("P::S2"), ID("X"), None) == 4096
    assert integration.get_size(ID("P::S"), ID("Y"), None) == 2048
    assert integration.get_size(ID("P::S"), ID("Y"), ID("S")) == 8192
    assert integration.get_size(ID("P::S"), ID("Z"), None) == 512
    assert integration.get_size(ID("P::S"), ID("Z"), ID("S")) == 512


@pytest.mark.parametrize(
    ("content", "error_msg", "line", "column"),
    [
        ('"', ["while scanning a quoted scalar", "unexpected end of stream"], 1, 2),
        ("Session: 1, Session : 1", ["mapping values are not allowed here"], 1, 21),
        (
            "Session: 1\nSession : 1",
            ["while constructing a mapping", 'found duplicate key "Session" with value "1"'],
            2,
            1,
        ),
    ],
)
def test_load_integration_file(
    tmp_path: Path, content: str, error_msg: Sequence[str], line: int, column: int
) -> None:
    test_rfi = tmp_path / "test.rfi"
    test_rfi.write_text(content)
    integration = Integration()
    error = RecordFluxError()
    regex = rf"^{test_rfi}:{line}:{column}: parser: error: "
    for elt in error_msg:
        regex += elt
        regex += rf'.*in "{test_rfi}", line [0-9]+, column [0-9]+.*'
    regex += "$"
    compiled_regex = re.compile(regex, re.DOTALL)
    integration.load_integration_file(test_rfi, error)
    with pytest.raises(RecordFluxError, match=compiled_regex):
        error.propagate()


def test_load_integration_path(tmp_path: Path) -> None:
    subfolder = tmp_path / "sub"
    subfolder.mkdir()
    test_rfi = subfolder / "test.rfi"
    test_rfi.write_text("{ Session: { Session : { Buffer_Size : 0 }}}")
    integration = Integration(integration_files_dir=subfolder)
    error = RecordFluxError()
    regex = re.compile(
        (
            r"^"
            r"test.rfi:0:0: parser: error: 1 validation error for IntegrationFile.*"
            r"value is not a valid dict \(type=type_error.dict\)"
            r"$"
        ),
        re.DOTALL,
    )
    integration.load_integration_file(tmp_path / "test.rflx", error)
    with pytest.raises(RecordFluxError, match=regex):
        error.propagate()
