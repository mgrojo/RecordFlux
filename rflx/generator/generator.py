from typing import Mapping, Sequence

from rflx.ada import (
    Assignment,
    CallStatement,
    CaseStatement,
    ExpressionFunctionDeclaration,
    FormalSubprogramDeclaration,
    FunctionSpecification,
    GenericProcedureInstantiation,
    InOutParameter,
    NullStatement,
    ObjectDeclaration,
    OutParameter,
    Parameter,
    Postcondition,
    Precondition,
    ProcedureSpecification,
    Subprogram,
    SubprogramBody,
    SubprogramDeclaration,
    UnitPart,
)
from rflx.common import unique
from rflx.expression import (
    TRUE,
    Add,
    Aggregate,
    And,
    AndThen,
    Call,
    Constrained,
    Div,
    Equal,
    Expr,
    ForAllIn,
    GreaterEqual,
    If,
    In,
    Indexed,
    Last,
    Length,
    LessEqual,
    Mod,
    NamedAggregate,
    Not,
    Number,
    Old,
    Or,
    Range,
    Selected,
    Size,
    Slice,
    Variable,
)
from rflx.identifier import ID
from rflx.model import BUILTINS_PACKAGE, FINAL, Enumeration, Field, Message, Opaque, Scalar, Type

from . import common, const


class GeneratorGenerator:
    def __init__(self, prefix: str = "") -> None:
        self.prefix = prefix

    def insert_function(self, type_name: ID) -> Subprogram:
        return GenericProcedureInstantiation(
            "Insert",
            ProcedureSpecification(
                const.TYPES * "Insert",
                [
                    Parameter(["Val"], type_name),
                    InOutParameter(["Buffer"], const.TYPES_BYTES),
                    Parameter(["Offset"], const.TYPES_OFFSET),
                ],
            ),
            [common.prefixed_type_name(type_name, self.prefix)],
        )

    def create_internal_functions(
        self, message: Message, scalar_fields: Mapping[Field, Scalar]
    ) -> UnitPart:
        return UnitPart(
            [],
            [
                SubprogramBody(
                    ProcedureSpecification(
                        "Set_Field_Value",
                        [
                            InOutParameter(["Ctx"], "Context"),
                            Parameter(["Val"], "Field_Dependent_Value"),
                            OutParameter(["Fst", "Lst"], const.TYPES_BIT_INDEX),
                        ],
                    ),
                    [
                        *common.field_bit_location_declarations(Variable("Val.Fld")),
                        *common.field_byte_location_declarations(),
                        *unique(
                            self.insert_function(common.full_base_type_name(t))
                            for t in message.types.values()
                            if isinstance(t, Scalar)
                        ),
                    ],
                    [
                        Assignment("Fst", Variable("First")),
                        Assignment("Lst", Variable("Last")),
                        CaseStatement(
                            Variable("Val.Fld"),
                            [
                                (
                                    Variable(f.affixed_name, immutable=True),
                                    [
                                        CallStatement(
                                            "Insert",
                                            [
                                                Variable(f"Val.{f.name}_Value"),
                                                Slice(
                                                    Variable("Ctx.Buffer.all"),
                                                    Variable("Buffer_First"),
                                                    Variable("Buffer_Last"),
                                                ),
                                                Variable("Offset"),
                                            ],
                                        )
                                        if f in scalar_fields
                                        else NullStatement()
                                    ],
                                )
                                for f in message.all_fields
                            ],
                        ),
                    ],
                    [
                        Precondition(
                            AndThen(
                                Not(Constrained("Ctx")),
                                Call("Has_Buffer", [Variable("Ctx")]),
                                In(Variable("Val.Fld"), Range("Field")),
                                Call("Valid_Next", [Variable("Ctx"), Variable("Val.Fld")]),
                                common.sufficient_space_for_field_condition(Variable("Val.Fld")),
                                ForAllIn(
                                    "F",
                                    Range("Field"),
                                    If(
                                        [
                                            (
                                                Call(
                                                    "Structural_Valid",
                                                    [
                                                        Indexed(
                                                            Variable("Ctx.Cursors"), Variable("F"),
                                                        )
                                                    ],
                                                ),
                                                LessEqual(
                                                    Selected(
                                                        Indexed(
                                                            Variable("Ctx.Cursors"), Variable("F"),
                                                        ),
                                                        "Last",
                                                    ),
                                                    Call(
                                                        "Field_Last",
                                                        [Variable("Ctx"), Variable("Val.Fld")],
                                                    ),
                                                ),
                                            )
                                        ]
                                    ),
                                ),
                            )
                        ),
                        Postcondition(
                            And(
                                Call("Has_Buffer", [Variable("Ctx")]),
                                Equal(
                                    Variable("Fst"),
                                    Call("Field_First", [Variable("Ctx"), Variable("Val.Fld")]),
                                ),
                                Equal(
                                    Variable("Lst"),
                                    Call("Field_Last", [Variable("Ctx"), Variable("Val.Fld")]),
                                ),
                                GreaterEqual(Variable("Fst"), Variable("Ctx.First")),
                                LessEqual(Variable("Fst"), Add(Variable("Lst"), Number(1))),
                                LessEqual(
                                    Call(const.TYPES_BYTE_INDEX, [Variable("Lst")]),
                                    Variable("Ctx.Buffer_Last"),
                                ),
                                ForAllIn(
                                    "F",
                                    Range("Field"),
                                    If(
                                        [
                                            (
                                                Call(
                                                    "Structural_Valid",
                                                    [
                                                        Indexed(
                                                            Variable("Ctx.Cursors"), Variable("F"),
                                                        )
                                                    ],
                                                ),
                                                LessEqual(
                                                    Selected(
                                                        Indexed(
                                                            Variable("Ctx.Cursors"), Variable("F"),
                                                        ),
                                                        "Last",
                                                    ),
                                                    Variable("Lst"),
                                                ),
                                            )
                                        ]
                                    ),
                                ),
                                *[
                                    Equal(e, Old(e))
                                    for e in [
                                        Variable("Ctx.Buffer_First"),
                                        Variable("Ctx.Buffer_Last"),
                                        Variable("Ctx.First"),
                                        Variable("Ctx.Cursors"),
                                    ]
                                ],
                            )
                        ),
                    ],
                )
            ]
            if scalar_fields
            else [],
        )

    def create_scalar_setter_procedures(
        self, message: Message, scalar_fields: Mapping[Field, Scalar]
    ) -> UnitPart:
        def specification(field: Field, field_type: Type) -> ProcedureSpecification:
            if field_type.package == BUILTINS_PACKAGE:
                type_name = ID(field_type.name)
            elif isinstance(field_type, Enumeration) and field_type.always_valid:
                type_name = common.prefixed_type_name(
                    common.full_enum_name(field_type), self.prefix
                )
            else:
                type_name = common.prefixed_type_name(field_type.identifier, self.prefix)

            return ProcedureSpecification(
                f"Set_{field.name}",
                [InOutParameter(["Ctx"], "Context"), Parameter(["Val"], type_name)],
            )

        return UnitPart(
            [
                SubprogramDeclaration(
                    specification(f, t),
                    [
                        Precondition(
                            AndThen(
                                *self.setter_preconditions(f),
                                Call(
                                    "Field_Condition",
                                    [
                                        Variable("Ctx"),
                                        Aggregate(
                                            Variable(f.affixed_name, immutable=True),
                                            Call("To_Base", [Variable("Val")]),
                                        ),
                                    ],
                                ),
                                Call("Valid", [Call("To_Base", [Variable("Val")])])
                                if not isinstance(t, Enumeration)
                                else TRUE,
                                common.sufficient_space_for_field_condition(
                                    Variable(f.affixed_name, immutable=True)
                                ),
                            )
                        ),
                        Postcondition(
                            And(
                                Call("Has_Buffer", [Variable("Ctx")]),
                                Call(
                                    "Valid",
                                    [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                                ),
                                Equal(
                                    Call(f"Get_{f.name}", [Variable("Ctx")]),
                                    Aggregate(TRUE, Variable("Val"))
                                    if isinstance(t, Enumeration) and t.always_valid
                                    else Variable("Val"),
                                ),
                                *self.setter_postconditions(message, f),
                                *[
                                    Equal(
                                        Call(
                                            "Context_Cursor",
                                            [
                                                Variable("Ctx"),
                                                Variable(p.affixed_name, immutable=True),
                                            ],
                                        ),
                                        Old(
                                            Call(
                                                "Context_Cursor",
                                                [
                                                    Variable("Ctx"),
                                                    Variable(p.affixed_name, immutable=True),
                                                ],
                                            )
                                        ),
                                    )
                                    for p in message.predecessors(f)
                                ],
                            )
                        ),
                    ],
                )
                for f, t in scalar_fields.items()
            ],
            [
                SubprogramBody(
                    specification(f, t),
                    [
                        ObjectDeclaration(
                            ["Field_Value"],
                            "Field_Dependent_Value",
                            Aggregate(
                                Variable(f.affixed_name, immutable=True),
                                Call("To_Base", [Variable("Val")]),
                            ),
                            True,
                        ),
                        ObjectDeclaration(["First", "Last"], const.TYPES_BIT_INDEX),
                    ],
                    [
                        CallStatement(
                            "Reset_Dependent_Fields",
                            [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                        ),
                        CallStatement(
                            "Set_Field_Value",
                            [
                                Variable("Ctx"),
                                Variable("Field_Value"),
                                Variable("First"),
                                Variable("Last"),
                            ],
                        ),
                        Assignment(
                            "Ctx",
                            Aggregate(
                                Variable("Ctx.Buffer_First"),
                                Variable("Ctx.Buffer_Last"),
                                Variable("Ctx.First"),
                                Variable("Last"),
                                Variable("Ctx.Buffer"),
                                Variable("Ctx.Cursors"),
                            ),
                        ),
                        Assignment(
                            Indexed(
                                Variable("Ctx.Cursors"), Variable(f.affixed_name, immutable=True)
                            ),
                            NamedAggregate(
                                ("State", Variable("S_Valid")),
                                ("First", Variable("First")),
                                ("Last", Variable("Last")),
                                ("Value", Variable("Field_Value")),
                                (
                                    "Predecessor",
                                    Selected(
                                        Indexed(
                                            Variable("Ctx.Cursors"),
                                            Variable(f.affixed_name, immutable=True),
                                        ),
                                        "Predecessor",
                                    ),
                                ),
                            ),
                        ),
                        Assignment(
                            Indexed(
                                Variable("Ctx.Cursors"),
                                Call(
                                    "Successor",
                                    [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                                ),
                            ),
                            NamedAggregate(
                                ("State", Variable("S_Invalid")),
                                ("Predecessor", Variable(f.affixed_name, immutable=True)),
                            ),
                        ),
                    ],
                )
                for f, t in scalar_fields.items()
            ],
        )

    def create_composite_setter_empty_procedures(self, message: Message) -> UnitPart:
        def specification(field: Field) -> ProcedureSpecification:
            return ProcedureSpecification(
                f"Set_{field.name}_Empty", [InOutParameter(["Ctx"], "Context")]
            )

        return UnitPart(
            [
                *[
                    SubprogramDeclaration(
                        specification(f),
                        [
                            Precondition(
                                AndThen(
                                    *self.setter_preconditions(f),
                                    *self.unbounded_composite_setter_preconditions(message, f),
                                    Equal(
                                        Call(
                                            "Field_Length",
                                            [
                                                Variable("Ctx"),
                                                Variable(f.affixed_name, immutable=True),
                                            ],
                                        ),
                                        Number(0),
                                    ),
                                )
                            ),
                            Postcondition(And(*self.composite_setter_postconditions(message, f))),
                        ],
                    )
                    for f, t in message.types.items()
                    if message.is_possibly_empty(f)
                ],
            ],
            [
                SubprogramBody(
                    specification(f),
                    [
                        ObjectDeclaration(
                            ["First"],
                            const.TYPES_BIT_INDEX,
                            Call(
                                "Field_First",
                                [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                            ),
                            True,
                        ),
                        ObjectDeclaration(
                            ["Last"],
                            const.TYPES_BIT_INDEX,
                            Call(
                                "Field_Last",
                                [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                            ),
                            True,
                        ),
                    ],
                    [
                        CallStatement(
                            "Reset_Dependent_Fields",
                            [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                        ),
                        Assignment(
                            "Ctx",
                            Aggregate(
                                Variable("Ctx.Buffer_First"),
                                Variable("Ctx.Buffer_Last"),
                                Variable("Ctx.First"),
                                Variable("Last"),
                                Variable("Ctx.Buffer"),
                                Variable("Ctx.Cursors"),
                            ),
                        ),
                        Assignment(
                            Indexed(
                                Variable("Ctx.Cursors"), Variable(f.affixed_name, immutable=True)
                            ),
                            NamedAggregate(
                                ("State", Variable("S_Valid")),
                                ("First", Variable("First")),
                                ("Last", Variable("Last")),
                                (
                                    "Value",
                                    NamedAggregate(
                                        ("Fld", Variable(f.affixed_name, immutable=True))
                                    ),
                                ),
                                (
                                    "Predecessor",
                                    Selected(
                                        Indexed(
                                            Variable("Ctx.Cursors"),
                                            Variable(f.affixed_name, immutable=True),
                                        ),
                                        "Predecessor",
                                    ),
                                ),
                            ),
                        ),
                        Assignment(
                            Indexed(
                                Variable("Ctx.Cursors"),
                                Call(
                                    "Successor",
                                    [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                                ),
                            ),
                            NamedAggregate(
                                ("State", Variable("S_Invalid")),
                                ("Predecessor", Variable(f.affixed_name, immutable=True)),
                            ),
                        ),
                    ],
                )
                for f, t in message.types.items()
                if message.is_possibly_empty(f)
            ],
        )

    def create_composite_setter_procedures(self, message: Message) -> UnitPart:
        def specification(field: Field) -> ProcedureSpecification:
            return ProcedureSpecification(f"Set_{field.name}", [InOutParameter(["Ctx"], "Context")])

        def specification_bounded(field: Field) -> ProcedureSpecification:
            return ProcedureSpecification(
                f"Set_Bounded_{field.name}",
                [InOutParameter(["Ctx"], "Context"), Parameter(["Length"], const.TYPES_BIT_LENGTH)],
            )

        def formal_parameters(field: Field) -> Sequence[FormalSubprogramDeclaration]:
            return [
                FormalSubprogramDeclaration(
                    ProcedureSpecification(
                        f"Process_{field.name}", [OutParameter([field.name], const.TYPES_BYTES)],
                    )
                ),
                FormalSubprogramDeclaration(
                    FunctionSpecification(
                        "Valid_Length", "Boolean", [Parameter(["Length"], const.TYPES_LENGTH)],
                    )
                ),
            ]

        return UnitPart(
            [
                SubprogramDeclaration(
                    specification(f),
                    [
                        Precondition(
                            AndThen(
                                *self.setter_preconditions(f),
                                *self.unbounded_composite_setter_preconditions(message, f),
                                Call(
                                    "Valid_Length",
                                    [
                                        Call(
                                            const.TYPES_LENGTH,
                                            [
                                                Div(
                                                    Call(
                                                        "Field_Length",
                                                        [
                                                            Variable("Ctx"),
                                                            Variable(
                                                                f.affixed_name, immutable=True
                                                            ),
                                                        ],
                                                    ),
                                                    Size(const.TYPES_BYTE),
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            )
                        ),
                        Postcondition(And(*self.composite_setter_postconditions(message, f),)),
                    ],
                    formal_parameters(f),
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and unbounded_setter_required(message, f)
            ]
            + [
                SubprogramDeclaration(
                    specification_bounded(f),
                    [
                        Precondition(
                            AndThen(
                                *self.setter_preconditions(f),
                                *self.bounded_composite_setter_preconditions(message, f),
                                Call(
                                    "Valid_Length",
                                    [
                                        Call(
                                            const.TYPES_LENGTH,
                                            [Div(Variable("Length"), Size(const.TYPES_BYTE))],
                                        )
                                    ],
                                ),
                            )
                        ),
                        Postcondition(And(*self.composite_setter_postconditions(message, f),)),
                    ],
                    formal_parameters(f),
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and bounded_setter_required(message, f)
            ],
            [
                SubprogramBody(
                    specification(f),
                    [
                        *common.field_bit_location_declarations(
                            Variable(f.affixed_name, immutable=True)
                        ),
                        ExpressionFunctionDeclaration(
                            FunctionSpecification("Buffer_First", const.TYPES_INDEX),
                            Call(const.TYPES_BYTE_INDEX, [Variable("First")]),
                        ),
                        ExpressionFunctionDeclaration(
                            FunctionSpecification("Buffer_Last", const.TYPES_INDEX),
                            Call(const.TYPES_BYTE_INDEX, [Variable("Last")]),
                        ),
                    ],
                    [
                        CallStatement(f"Initialize_{f.name}", [Variable("Ctx")]),
                        CallStatement(
                            f"Process_{f.name}",
                            [
                                Slice(
                                    Selected(Variable("Ctx.Buffer"), "all"),
                                    Variable("Buffer_First"),
                                    Variable("Buffer_Last"),
                                ),
                            ],
                        ),
                    ],
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and unbounded_setter_required(message, f)
            ]
            + [
                SubprogramBody(
                    specification_bounded(f),
                    [
                        ObjectDeclaration(
                            ["First"],
                            const.TYPES_BIT_INDEX,
                            Call(
                                "Field_First",
                                [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                            ),
                            True,
                        ),
                        ObjectDeclaration(
                            ["Last"],
                            const.TYPES_BIT_INDEX,
                            Add(Variable("First"), Variable("Length"), -Number(1)),
                            True,
                        ),
                        ExpressionFunctionDeclaration(
                            FunctionSpecification("Buffer_First", const.TYPES_INDEX),
                            Call(const.TYPES_BYTE_INDEX, [Variable("First")]),
                        ),
                        ExpressionFunctionDeclaration(
                            FunctionSpecification("Buffer_Last", const.TYPES_INDEX),
                            Call(const.TYPES_BYTE_INDEX, [Variable("Last")]),
                        ),
                    ],
                    [
                        CallStatement(
                            f"Initialize_Bounded_{f.name}", [Variable("Ctx"), Variable("Length")]
                        ),
                        CallStatement(
                            f"Process_{f.name}",
                            [
                                Slice(
                                    Selected(Variable("Ctx.Buffer"), "all"),
                                    Variable("Buffer_First"),
                                    Variable("Buffer_Last"),
                                ),
                            ],
                        ),
                    ],
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and bounded_setter_required(message, f)
            ],
        )

    def create_composite_initialize_procedures(self, message: Message) -> UnitPart:
        def specification(field: Field) -> ProcedureSpecification:
            return ProcedureSpecification(
                f"Initialize_{field.name}", [InOutParameter(["Ctx"], "Context")]
            )

        def specification_bounded(field: Field) -> ProcedureSpecification:
            return ProcedureSpecification(
                f"Initialize_Bounded_{field.name}",
                [InOutParameter(["Ctx"], "Context"), Parameter(["Length"], const.TYPES_BIT_LENGTH)],
            )

        return UnitPart(
            [
                SubprogramDeclaration(
                    specification(f),
                    [
                        Precondition(
                            AndThen(
                                *self.setter_preconditions(f),
                                *self.unbounded_composite_setter_preconditions(message, f),
                            )
                        ),
                        Postcondition(And(*self.composite_setter_postconditions(message, f),)),
                    ],
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and unbounded_setter_required(message, f)
            ]
            + [
                SubprogramDeclaration(
                    specification_bounded(f),
                    [
                        Precondition(
                            AndThen(
                                *self.setter_preconditions(f),
                                *self.bounded_composite_setter_preconditions(message, f),
                            )
                        ),
                        Postcondition(And(*self.composite_setter_postconditions(message, f),)),
                    ],
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and bounded_setter_required(message, f)
            ],
            [
                SubprogramBody(
                    specification(f),
                    common.field_bit_location_declarations(
                        Variable(f.affixed_name, immutable=True)
                    ),
                    common.initialize_field_statements(message, f, self.prefix),
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and unbounded_setter_required(message, f)
            ]
            + [
                SubprogramBody(
                    specification_bounded(f),
                    [
                        ObjectDeclaration(
                            ["First"],
                            const.TYPES_BIT_INDEX,
                            Call(
                                "Field_First",
                                [Variable("Ctx"), Variable(f.affixed_name, immutable=True)],
                            ),
                            True,
                        ),
                        ObjectDeclaration(
                            ["Last"],
                            const.TYPES_BIT_INDEX,
                            Add(Variable("First"), Variable("Length"), -Number(1)),
                            True,
                        ),
                    ],
                    common.initialize_field_statements(message, f, self.prefix),
                )
                for f, t in message.types.items()
                if isinstance(t, Opaque) and bounded_setter_required(message, f)
            ],
        )

    @staticmethod
    def setter_preconditions(field: Field) -> Sequence[Expr]:
        return [
            Not(Constrained("Ctx")),
            Call("Has_Buffer", [Variable("Ctx")]),
            Call("Valid_Next", [Variable("Ctx"), Variable(field.affixed_name, immutable=True)]),
            LessEqual(
                Call("Field_Last", [Variable("Ctx"), Variable(field.affixed_name, immutable=True)]),
                Div(Last(const.TYPES_BIT_INDEX), Number(2)),
            ),
        ]

    @staticmethod
    def setter_postconditions(message: Message, field: Field) -> Sequence[Expr]:
        return [
            *[
                Call("Invalid", [Variable("Ctx"), Variable(p.affixed_name, immutable=True)])
                for p in message.successors(field)
                if p != FINAL
            ],
            *common.valid_path_to_next_field_condition(message, field),
            *[
                Equal(e, Old(e))
                for e in [
                    Variable("Ctx.Buffer_First"),
                    Variable("Ctx.Buffer_Last"),
                    Variable("Ctx.First"),
                    Call(
                        "Predecessor",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                    Call(
                        "Valid_Next",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                ]
                + [
                    Call(f"Get_{p.name}", [Variable("Ctx")])
                    for p in message.definite_predecessors(field)
                    if isinstance(message.types[p], Scalar)
                ]
            ],
        ]

    def composite_setter_postconditions(self, message: Message, field: Field) -> Sequence[Expr]:
        return [
            Call("Has_Buffer", [Variable("Ctx")]),
            *self.setter_postconditions(message, field),
            Call(
                "Structural_Valid", [Variable("Ctx"), Variable(field.affixed_name, immutable=True)]
            ),
        ]

    @staticmethod
    def unbounded_composite_setter_preconditions(message: Message, field: Field) -> Sequence[Expr]:
        return [
            Call(
                "Field_Condition",
                [
                    Variable("Ctx"),
                    NamedAggregate(("Fld", Variable(field.affixed_name, immutable=True))),
                ]
                + (
                    [
                        Call(
                            "Field_Length",
                            [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                        )
                    ]
                    if common.length_dependent_condition(message)
                    else []
                ),
            ),
            common.sufficient_space_for_field_condition(
                Variable(field.affixed_name, immutable=True)
            ),
            Equal(
                Mod(
                    Call(
                        "Field_First",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                    Size(const.TYPES_BYTE),
                ),
                Number(1),
            ),
            Equal(
                Mod(
                    Call(
                        "Field_Length",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                    Size(const.TYPES_BYTE),
                ),
                Number(0),
            ),
        ]

    @staticmethod
    def bounded_composite_setter_preconditions(message: Message, field: Field) -> Sequence[Expr]:
        return [
            Call(
                "Field_Condition",
                [
                    Variable("Ctx"),
                    NamedAggregate(("Fld", Variable(field.affixed_name, immutable=True))),
                ]
                + ([Variable("Length")] if common.length_dependent_condition(message) else []),
            ),
            GreaterEqual(
                Call(
                    "Available_Space",
                    [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                ),
                Variable("Length"),
            ),
            LessEqual(
                Add(
                    Call(
                        "Field_First",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                    Variable("Length"),
                ),
                Div(Last(const.TYPES_BIT_INDEX), Number(2)),
            ),
            Or(
                *[
                    And(
                        *[
                            Call(
                                "Valid",
                                [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                            )
                            for field in message.fields
                            if Variable(field.name) in l.condition.variables()
                        ],
                        l.condition.substituted(
                            mapping={
                                Variable(field.name): Call(f"Get_{field.name}", [Variable("Ctx")])
                                for field in message.fields
                                if Variable(field.name) in l.condition.variables()
                            }
                        ),
                    )
                    for l in message.incoming(field)
                    if Last("Message") in l.length
                ]
            ),
            Equal(
                Mod(
                    Call(
                        "Field_First",
                        [Variable("Ctx"), Variable(field.affixed_name, immutable=True)],
                    ),
                    Size(const.TYPES_BYTE),
                ),
                Number(1),
            ),
            Equal(Mod(Variable("Length"), Size(const.TYPES_BYTE)), Number(0),),
        ]


def unbounded_setter_required(message: Message, field: Field) -> bool:
    return any(
        True
        for l in message.incoming(field)
        if Length("Message") not in l.length and Last("Message") not in l.length
    )


def bounded_setter_required(message: Message, field: Field) -> bool:
    return any(
        True
        for l in message.incoming(field)
        if Length("Message") in l.length or Last("Message") in l.length
    )
