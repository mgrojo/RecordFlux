class Tai64:
    UNIX_EPOCH: Tai64
    BYTES_SIZE: int

    @staticmethod
    def now() -> Tai64: ...
    @staticmethod
    def from_bytes(data: bytes) -> Tai64: ...
    @staticmethod
    def from_unix(specs: int) -> Tai64: ...
    def to_bytes(self) -> bytes: ...
    def to_unix(self) -> int: ...
    def __add__(self, other: int) -> Tai64: ...

class Tai64n:
    UNIX_EPOCH: Tai64n
    BYTES_SIZE: int

    @staticmethod
    def now() -> Tai64n: ...
    @staticmethod
    def from_bytes(data: bytes) -> Tai64n: ...
    def to_bytes(self) -> bytes: ...
