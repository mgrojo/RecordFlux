from langkit.parsers import Grammar, List, NoBacktrack as cut, Opt, Or  # type: ignore

import language.ast as ast
from language.lexer import rflx_lexer as lexer

rflx_grammar = Grammar("main_rule")
grammar = rflx_grammar

rflx_grammar.add_rules(
    main_rule=Opt(grammar.specification),
)

rflx_grammar.add_rules(
    unqualified_identifier=ast.UnqualifiedID(lexer.UnqualifiedIdentifier),
    qualified_identifier=ast.ID(
        Opt(grammar.unqualified_identifier, "::"), grammar.unqualified_identifier
    ),
    numeric_literal=ast.NumericLiteral(lexer.Numeral),
    qualified_variable=ast.Variable(grammar.qualified_identifier),
    first_attribute=ast.FirstAttribute(grammar.unqualified_identifier, "'", lexer.First),
    length_attribute=ast.SizeAttribute(grammar.unqualified_identifier, "'", lexer.Size),
    last_attribute=ast.LastAttribute(grammar.unqualified_identifier, "'", lexer.Last),
    valid_checksum_attribute=ast.ValidChecksumAttribute(
        grammar.unqualified_identifier, "'", lexer.ValidChecksum
    ),
    array_aggregate=ast.ArrayAggregate("[", List(grammar.numeric_literal, sep=","), "]"),
    string_literal=ast.StringLiteral(lexer.StringLiteral),
    concatenation=Or(
        ast.Concatenation(
            grammar.concatenation,
            "&",
            cut(),
            Or(grammar.array_aggregate, grammar.string_literal),
        ),
        Or(grammar.array_aggregate, grammar.string_literal),
    ),
    primary=Or(
        grammar.concatenation,
        grammar.numeric_literal,
        grammar.first_attribute,
        grammar.length_attribute,
        grammar.last_attribute,
        grammar.valid_checksum_attribute,
        grammar.qualified_variable,
        grammar.paren_expression,
    ),
    binop=Or(
        # pylint: disable=no-member
        ast.Op.alt_pow("**"),
        ast.Op.alt_mul("*"),
        ast.Op.alt_div("/"),
        ast.Op.alt_add("+"),
        ast.Op.alt_sub("-"),
        ast.Op.alt_eq("="),
        ast.Op.alt_neq("/="),
        ast.Op.alt_le("<="),
        ast.Op.alt_lt("<"),
        ast.Op.alt_ge(">="),
        ast.Op.alt_gt(">"),
        ast.Op.alt_and("and"),
        ast.Op.alt_or("or"),
    ),
    paren_expression=ast.ParenExpression("(", grammar.expression, ")"),
    expression=Or(
        ast.BinOp(
            grammar.expression,
            grammar.binop,
            cut(),
            grammar.primary,
        ),
        grammar.primary,
    ),
    mathematical_expression=ast.MathematicalExpression(grammar.expression),
    boolean_expression=ast.BooleanExpression(grammar.expression),
)

rflx_grammar.add_rules(
    mathematical_aspect=ast.MathematicalAspect(
        grammar.unqualified_identifier, "=>", grammar.mathematical_expression
    ),
    boolean_aspect=ast.BooleanAspect(
        grammar.unqualified_identifier, Opt("=>", grammar.boolean_expression)
    ),
    range_type_definition=ast.RangeTypeDef(
        "range",
        grammar.mathematical_expression,
        "..",
        grammar.mathematical_expression,
        "with",
        grammar.mathematical_aspect,
    ),
    modular_type_definition=ast.ModularTypeDef("mod", grammar.mathematical_expression),
    integer_type_definition=Or(grammar.range_type_definition, grammar.modular_type_definition),
    if_condition=ast.If("if", grammar.boolean_expression),
    then=ast.Then(
        "then",
        Or(ast.NullID("null"), grammar.unqualified_identifier),
        Opt("with", List(grammar.mathematical_aspect, sep=",")),
        Opt(grammar.if_condition),
    ),
    null_component_item=ast.NullComponent("null", grammar.then, ";"),
    component_item=ast.Component(
        grammar.unqualified_identifier,
        ":",
        grammar.qualified_identifier,
        Opt("with", List(grammar.mathematical_aspect, sep=",")),
        Opt(grammar.if_condition),
        List(grammar.then, empty_valid=True),
        ";",
    ),
    component_list=ast.Components(Opt(grammar.null_component_item), List(grammar.component_item)),
    value_range=ast.ValueRange(
        grammar.mathematical_expression, "..", grammar.mathematical_expression
    ),
    checksum_association=ast.ChecksumAssoc(
        grammar.unqualified_identifier,
        "=>",
        "(",
        List(Or(grammar.value_range, grammar.mathematical_expression), sep=","),
        ")",
    ),
    checksum_aspect=ast.ChecksumAspect(
        "Checksum", "=>", "(", List(grammar.checksum_association), ")"
    ),
    message_type_definition=Or(
        ast.MessageTypeDef(
            "message",
            grammar.component_list,
            "end",
            "message",
            Opt("with", grammar.checksum_aspect),
        ),
        ast.NullMessageTypeDef("null", "message"),
    ),
    positional_enumeration=ast.NamedEnumeration(List(grammar.unqualified_identifier, sep=",")),
    element_value_association=ast.ElementValueAssoc(
        grammar.unqualified_identifier, "=>", grammar.numeric_literal
    ),
    named_enumeration=ast.PositionalEnumeration(List(grammar.element_value_association, sep=",")),
    enumeration_aspects=List(Or(grammar.mathematical_aspect, grammar.boolean_aspect), sep=","),
    enumeration_type_definition=ast.EnumerationTypeDef(
        "(",
        Or(grammar.named_enumeration, grammar.positional_enumeration),
        ")",
        "with",
        grammar.enumeration_aspects,
    ),
    type_derivation_definition=ast.TypeDerivationDef(
        "new",
        grammar.qualified_identifier,
    ),
    array_type_definition=ast.ArrayTypeDef(
        "array",
        "of",
        grammar.qualified_identifier,
    ),
    type_declaration=ast.Type(
        "type",
        grammar.unqualified_identifier,
        "is",
        Or(
            grammar.enumeration_type_definition,
            grammar.integer_type_definition,
            grammar.message_type_definition,
            grammar.type_derivation_definition,
            grammar.array_type_definition,
        ),
    ),
    type_refinement=ast.Refinement(
        "for",
        grammar.qualified_identifier,
        "use",
        "(",
        grammar.unqualified_identifier,
        "=>",
        grammar.qualified_identifier,
        ")",
        Opt(grammar.if_condition),
    ),
    private_type_declaration=ast.PrivateTypeDecl(
        "type", grammar.unqualified_identifier, "is", "private"
    ),
    function_parameter=ast.Parameter(
        grammar.unqualified_identifier, ":", grammar.qualified_identifier
    ),
    function_parameter_list=ast.Parameters("(", List(grammar.function_parameter, sep=";"), ")"),
    formal_function_declaration=ast.FunctionDecl(
        "with",
        "function",
        grammar.unqualified_identifier,
        Opt(grammar.function_parameter_list),
        "return",
        grammar.qualified_identifier,
    ),
    channel_declaration=ast.ChannelDecl(
        grammar.unqualified_identifier,
        ":",
        "Channel",
        "with",
        List(Or(ast.Readable("Readable"), ast.Writable("Writable")), sep=","),
    ),
    session_parameter=Or(
        grammar.private_type_declaration,
        grammar.formal_function_declaration,
        grammar.channel_declaration,
    ),
    session_aspects=ast.SessionAspects(
        "with",
        "Initial",
        "=>",
        grammar.unqualified_identifier,
        ",",
        "Final",
        "=>",
        grammar.unqualified_identifier,
    ),
    renaming_declaration=ast.RenamingDecl(
        grammar.unqualified_identifier,
        ":",
        grammar.qualified_identifier,
        "renames",
        ast.Selected(grammar.unqualified_identifier, ".", grammar.unqualified_identifier),
    ),
    variable_declaration=ast.VariableDecl(
        grammar.unqualified_identifier,
        ":",
        grammar.qualified_identifier,
        Opt(":=", grammar.expression),
    ),
    declaration=Or(grammar.renaming_declaration, grammar.variable_declaration),
    description_aspect=ast.Description("Desc", "=>", grammar.string_literal),
    null_state_body=ast.NullStateBody("null", "state"),
    assignment_statement=ast.Assignment(grammar.unqualified_identifier, ":=", grammar.expression),
    list_attribute=ast.ListAttribute(
        grammar.unqualified_identifier,
        "'",
        Or(
            # pylint: disable=no-member
            ast.Attr.alt_append("Append"),
            ast.Attr.alt_extend("Extend"),
            ast.Attr.alt_read("Read"),
            ast.Attr.alt_write("Write"),
        ),
        "(",
        grammar.expression,
        ")",
    ),
    reset=ast.Reset(grammar.unqualified_identifier, "'", "Reset"),
    attribute_statement=Or(grammar.list_attribute, grammar.reset),
    action=Or(grammar.assignment_statement, grammar.attribute_statement),
    conditional_transition=ast.ConditionalTransition(
        "then",
        grammar.unqualified_identifier,
        Opt(grammar.description_aspect),
        grammar.if_condition,
    ),
    transition=ast.Transition(
        "then", grammar.unqualified_identifier, Opt(grammar.description_aspect)
    ),
    state_body=ast.StateBody(
        Opt(List(grammar.declaration, sep=";"), ";"),
        "begin",
        Opt(List(grammar.action, sep=";"), ";"),
        "transition",
        List(grammar.conditional_transition, empty_valid=True),
        grammar.transition,
        "end",
        grammar.unqualified_identifier,
    ),
    state=ast.State(
        "state",
        grammar.unqualified_identifier,
        Opt(grammar.description_aspect),
        "is",
        Or(grammar.null_state_body, grammar.state_body),
    ),
    session_declaration=ast.Session(
        "generic",
        Opt(List(grammar.session_parameter, sep=";"), ";"),
        "session",
        grammar.unqualified_identifier,
        grammar.session_aspects,
        "is",
        Opt(List(grammar.declaration, sep=";"), ";"),
        "begin",
        Opt(List(grammar.state, sep=";"), ";"),
        "end",
        grammar.unqualified_identifier,
        ";",
    ),
    basic_declaration=Or(
        grammar.type_declaration, grammar.type_refinement, grammar.session_declaration
    ),
    package_declaration=ast.PackageDeclarationNode(
        "package",
        grammar.unqualified_identifier,
        "is",
        Opt(List(grammar.basic_declaration, sep=";"), ";"),
        "end",
        grammar.unqualified_identifier,
        ";",
    ),
    context_item=List("with", grammar.unqualified_identifier, ";"),
    specification=ast.Specification(
        List(grammar.context_item, empty_valid=True), grammar.package_declaration
    ),
)
