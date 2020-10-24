from langkit.lexer import (  # type: ignore
    Alt,
    Case,
    Ignore,
    Lexer,
    LexerToken,
    Literal,
    Pattern,
    WithSymbol,
    WithText,
    WithTrivia,
)


class Token(LexerToken):
    # Identifiers
    UnqualifiedIdentifier = WithSymbol()

    # Keywords
    Package = WithText()
    Is = WithText()
    If = WithText()
    End = WithText()
    Null = WithText()
    Semicolon = WithText()
    DoubleColon = WithText()
    Assignment = WithText()
    Colon = WithText()
    Type = WithText()
    Range = WithText()
    With = WithText()
    Mod = WithText()
    Message = WithText()
    Then = WithText()
    Array = WithText()
    Of = WithText()
    New = WithText()
    For = WithText()
    Use = WithText()
    Generic = WithText()
    Session = WithText()
    Begin = WithText()
    Private = WithText()
    Return = WithText()
    Function = WithText()
    State = WithText()
    Transition = WithText()
    Renames = WithText()
    Channel = WithText()
    Readable = WithText()
    Writable = WithText()
    Desc = WithText()
    Append = WithText()
    Extend = WithText()
    Read = WithText()
    Write = WithText()
    Reset = WithText()

    # Aspect names
    First = WithText()
    Size = WithText()
    Last = WithText()
    Checksum = WithText()
    ValidChecksum = WithText()
    Initial = WithText()
    Final = WithText()

    # Symbols
    Dot = WithText()
    Comma = WithText()
    DoubleDot = WithText()
    Tick = WithText()
    Hash = WithText()
    Minus = WithText()
    Arrow = WithText()
    LPar = WithText()
    RPar = WithText()
    LBrack = WithText()
    RBrack = WithText()
    Exp = WithText()
    Mul = WithText()
    Div = WithText()
    Add = WithText()
    Sub = WithText()
    Eq = WithText()
    Neq = WithText()
    Leq = WithText()
    Lt = WithText()
    Le = WithText()
    Gt = WithText()
    Ge = WithText()
    And = WithText()
    Or = WithText()
    Ampersand = WithText()

    # Comment
    Comment = WithTrivia()

    # Numeric
    Numeral = WithText()

    # String
    StringLiteral = WithText()


rflx_lexer = Lexer(Token)

rflx_lexer.add_rules(
    (Pattern(r"[ \t\r\n]+"), Ignore()),
    (Pattern(r"--.*"), Token.Comment),
)

# Hack to support keywords that equal attributes
# Inspired by Libadalang grammar (ada/language/lexer.py)
rflx_lexer.add_rules(
    *[
        Case(
            Literal(text),
            Alt(
                prev_token_cond=(Token.Tick,),
                send=token,
                match_size=len(text),
            ),
            Alt(send=Token.UnqualifiedIdentifier, match_size=len(text)),
        )
        for text, token in [
            ("First", Token.First),
            ("Last", Token.Last),
            ("Size", Token.Size),
            ("Valid_Checksum", Token.Size),
        ]
    ]
)

rflx_lexer.add_rules(
    *[
        Case(
            Literal(text),
            Alt(
                prev_token_cond=(Token.With,),
                send=token,
                match_size=len(text),
            ),
            Alt(send=Token.UnqualifiedIdentifier, match_size=len(text)),
        )
        for text, token in [
            ("Checksum", Token.Checksum),
        ]
    ]
)

rflx_lexer.add_rules(
    (Literal("package"), Token.Package),
    (Literal("is"), Token.Is),
    (Literal("if"), Token.Is),
    (Literal("end"), Token.End),
    (Literal("null"), Token.Null),
    (Literal("type"), Token.Type),
    (Literal("range"), Token.Range),
    (Literal("with"), Token.With),
    (Literal("mod"), Token.Mod),
    (Literal("message"), Token.Message),
    (Literal("then"), Token.Then),
    (Literal("array"), Token.Array),
    (Literal("of"), Token.Of),
    (Literal("new"), Token.New),
    (Literal("for"), Token.For),
    (Literal("use"), Token.Use),
    (Literal("generic"), Token.Generic),
    (Literal("session"), Token.Session),
    (Literal("begin"), Token.Begin),
    (Literal("private"), Token.Private),
    (Literal("return"), Token.Return),
    (Literal("function"), Token.Function),
    (Literal("state"), Token.State),
    (Literal("transition"), Token.Transition),
    (Literal("renames"), Token.Renames),
    (Literal("Channel"), Token.Channel),
    (Literal("Readable"), Token.Readable),
    (Literal("Writable"), Token.Writable),
    (Literal("Desc"), Token.Desc),
    (Literal("Append"), Token.Append),
    (Literal("Extend"), Token.Extend),
    (Literal("Read"), Token.Read),
    (Literal("Write"), Token.Write),
    (Literal("Reset"), Token.Reset),
    (Literal("Checksum"), Token.Checksum),
    (Literal("Valid_Checksum"), Token.ValidChecksum),
    (Literal("Initial"), Token.Initial),
    (Literal("Final"), Token.Final),
    (Literal(";"), Token.Semicolon),
    (Literal("::"), Token.DoubleColon),
    (Literal(":="), Token.Assignment),
    (Literal(":"), Token.Colon),
    (Literal("("), Token.LPar),
    (Literal(")"), Token.RPar),
    (Literal("["), Token.LBrack),
    (Literal("]"), Token.RBrack),
    (Literal(".."), Token.DoubleDot),
    (Literal("."), Token.Dot),
    (Literal(","), Token.Comma),
    (Literal("'"), Token.Tick),
    (Literal("#"), Token.Hash),
    (Literal("**"), Token.Exp),
    (Literal("*"), Token.Mul),
    (Literal("/="), Token.Neq),
    (Literal("/"), Token.Div),
    (Literal("+"), Token.Add),
    (Literal("-"), Token.Sub),
    (Literal("="), Token.Eq),
    (Literal("<="), Token.Le),
    (Literal("<"), Token.Lt),
    (Literal(">="), Token.Ge),
    (Literal(">"), Token.Gt),
    (Literal("and"), Token.And),
    (Literal("or"), Token.Or),
    (Literal("&"), Token.Ampersand),
    (Literal("=>"), Token.Arrow),
    (Pattern(r'"[^"]*"'), Token.StringLiteral),
    (Pattern(r"[0-9]+(_?[0-9]+)*"), Token.Numeral),
    (Pattern(r"[0-9]+#[0-9A-F]+(_?[0-9A-F]+)*#"), Token.Numeral),
    (Pattern(r"[a-zA-Z][a-zA-Z0-9_]*"), Token.UnqualifiedIdentifier),
)
