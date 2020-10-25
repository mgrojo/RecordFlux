from langkit.dsl import ASTNode, Field, abstract  # type: ignore


@abstract
class RFLXNode(ASTNode):
    pass


class NullID(RFLXNode):
    pass


class UnqualifiedID(RFLXNode):
    token_node = True


class ID(RFLXNode):
    package = Field()
    name = Field()


class PackageDeclarationNode(RFLXNode):
    name_start = Field()
    content = Field()
    name_end = Field()


@abstract
class TypeDef(RFLXNode):
    pass


@abstract
class IntegerTypeDef(TypeDef):
    pass


class RangeTypeDef(IntegerTypeDef):
    lower = Field()
    upper = Field()
    size = Field()


class ModularTypeDef(IntegerTypeDef):
    mod = Field()


@abstract
class AbstractMessageTypeDef(TypeDef):
    pass


class NullMessageTypeDef(AbstractMessageTypeDef):
    pass


class TypeDerivationDef(TypeDef):
    type_name = Field()


class ArrayTypeDef(TypeDef):
    type_name = Field()


@abstract
class Enumeration(TypeDef):
    pass


class NamedEnumeration(Enumeration):
    elements = Field()


class PositionalEnumeration(Enumeration):
    elements = Field()


class EnumerationTypeDef(TypeDef):
    elements = Field()
    aspects = Field()


class ElementValueAssoc(TypeDef):
    name = Field()
    literal = Field()


class MessageTypeDef(AbstractMessageTypeDef):
    components = Field()
    checksums = Field()


class Type(RFLXNode):
    identifier = Field()
    type_definition = Field(type=TypeDef)


class Refinement(RFLXNode):
    pdu = Field()
    field = Field()
    sdu = Field()
    condition = Field()


class NumericLiteral(RFLXNode):
    token_node = True


@abstract
class Aspect(RFLXNode):
    pass


class MathematicalAspect(Aspect):
    name = Field()
    value = Field()


class BooleanAspect(Aspect):
    name = Field()
    value = Field()


class Then(RFLXNode):
    name = Field()
    aspects = Field()
    condition = Field()


class If(RFLXNode):
    condition = Field()


class NullComponent(RFLXNode):
    then = Field()


class Component(RFLXNode):
    name = Field()
    type_name = Field()
    first = Field()
    size = Field()
    thens = Field()


class Components(RFLXNode):
    null_component = Field()
    components = Field()


class ValueRange(RFLXNode):
    lower = Field()
    upper = Field()


class ChecksumAssoc(RFLXNode):
    name = Field()
    covered_fields = Field()


class ChecksumAspect(RFLXNode):
    associations = Field()


class Variable(RFLXNode):
    name = Field()


class QualifiedVariable(RFLXNode):
    name = Field()


class Op(RFLXNode):
    enum_node = True
    alternatives = [
        "pow",
        "mul",
        "div",
        "add",
        "sub",
        "eq",
        "neq",
        "le",
        "lt",
        "gt",
        "ge",
        "and",
        "or",
        "in",
        "notin",
        "select",
    ]


class BinOp(RFLXNode):
    left = Field()
    op = Field(type=Op)
    right = Field()


class ParenExpression(RFLXNode):
    expr = Field()


class BooleanExpression(RFLXNode):
    expr = Field()


class MathematicalExpression(RFLXNode):
    expr = Field()


class AttrBase(RFLXNode):
    pass


class Attr(AttrBase):
    enum_node = True
    alternatives = [
        "First",
        "Size",
        "Last",
        "Valid_Checksum",
    ]


class ExtAttr(AttrBase):
    enum_node = True
    alternatives = [
        "Head",
        "Opaque",
        "Present",
        "Valid",
    ]


class Attribute(RFLXNode):
    expression = Field()
    kind = Field(type=AttrBase)


class Specification(RFLXNode):
    context_clause = Field()
    package_declaration = Field()


class Concatenation(RFLXNode):
    left = Field()
    right = Field()


class ArrayAggregate(RFLXNode):
    values = Field()


class StringLiteral(RFLXNode):
    token_node = True


class Session(RFLXNode):
    parameters = Field()
    name = Field()
    aspects = Field()
    declarations = Field()
    states = Field()
    end_identifier = Field()


class VariableDecl(RFLXNode):
    name = Field()
    type_name = Field()
    initializer = Field()


class Selected(RFLXNode):
    prefix = Field()
    selector = Field()


class RenamingDecl(RFLXNode):
    name = Field()
    type_name = Field()
    expression = Field(type=Selected)


class PrivateTypeDecl(RFLXNode):
    name = Field()


class Parameter(RFLXNode):
    name = Field()
    type_name = Field()


class Parameters(RFLXNode):
    parameters = Field()


class FunctionDecl(RFLXNode):
    name = Field()
    parameters = Field()
    return_type_name = Field()


class Readable(RFLXNode):
    pass


class Writable(RFLXNode):
    pass


class ChannelDecl(RFLXNode):
    name = Field()
    parameters = Field()


class SessionAspects(RFLXNode):
    initial = Field(type=UnqualifiedID)
    final = Field(type=UnqualifiedID)


class State(RFLXNode):
    name = Field()
    description = Field()
    body = Field()


class NullStateBody(RFLXNode):
    pass


class StateBody(RFLXNode):
    declarations = Field()
    actions = Field()
    conditional_transitions = Field()
    final_transition = Field()
    end_identifier = Field()


class Description(RFLXNode):
    content = Field()


class Assignment(RFLXNode):
    name = Field()
    expression = Field()


class ListAttr(RFLXNode):
    enum_node = True
    alternatives = [
        "Append",
        "Extend",
        "Read",
        "Write",
    ]


class Quant(RFLXNode):
    enum_node = True
    alternatives = [
        "all",
        "some",
    ]


class QuantifiedExpression(RFLXNode):
    operation = Field(type=Quant)
    parameter_identifier = Field()
    iterable = Field()
    predicate = Field()


class ListAttribute(RFLXNode):
    name = Field()
    attr = Field(type=ListAttr)
    expression = Field()


class Reset(RFLXNode):
    name = Field()


class Transition(RFLXNode):
    target = Field()
    description = Field()


class ConditionalTransition(Transition):
    condition = Field()


class Comprehension(RFLXNode):
    iterator = Field()
    array = Field()
    selector = Field()
    condition = Field()


class Call(RFLXNode):
    name = Field()
    arguments = Field()


class Conversion(RFLXNode):
    name = Field()
    argument = Field()


class MessageAggregate(RFLXNode):
    name = Field()
    values = Field()


class NullComponents(RFLXNode):
    pass


class MessageComponent(RFLXNode):
    name = Field()
    expression = Field()


class MessageComponents(NullComponents):
    components = Field()


class Where(RFLXNode):
    expression = Field()
    variable_name = Field()
    substitution = Field()
