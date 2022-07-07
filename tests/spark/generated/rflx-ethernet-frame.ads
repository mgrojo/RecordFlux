pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");
with RFLX.RFLX_Types;

package RFLX.Ethernet.Frame with
  SPARK_Mode,
  Annotate =>
    (GNATprove, Always_Return)
is

   pragma Warnings (Off, "use clause for type ""Base_Integer"" * has no effect");

   pragma Warnings (Off, "use clause for type ""Bytes"" * has no effect");

   pragma Warnings (Off, """BASE_INTEGER"" is already use-visible through previous use_type_clause");

   pragma Warnings (Off, """LENGTH"" is already use-visible through previous use_type_clause");

   use type RFLX_Types.Bytes;

   use type RFLX_Types.Byte;

   use type RFLX_Types.Bytes_Ptr;

   use type RFLX_Types.Length;

   use type RFLX_Types.Index;

   use type RFLX_Types.Bit_Index;

   use type RFLX_Types.Base_Integer;

   use type RFLX_Types.Offset;

   pragma Warnings (On, """LENGTH"" is already use-visible through previous use_type_clause");

   pragma Warnings (On, """BASE_INTEGER"" is already use-visible through previous use_type_clause");

   pragma Warnings (On, "use clause for type ""Base_Integer"" * has no effect");

   pragma Warnings (On, "use clause for type ""Bytes"" * has no effect");

   pragma Unevaluated_Use_Of_Old (Allow);

   type Virtual_Field is (F_Initial, F_Destination, F_Source, F_Type_Length_TPID, F_TPID, F_TCI, F_Type_Length, F_Payload, F_Final);

   subtype Field is Virtual_Field range F_Destination .. F_Payload;

   type Field_Cursor is private with
     Default_Initial_Condition =>
       False;

   type Field_Cursors is private with
     Default_Initial_Condition =>
       False;

   type Context (Buffer_First, Buffer_Last : RFLX_Types.Index := RFLX_Types.Index'First; First : RFLX_Types.Bit_Index := RFLX_Types.Bit_Index'First; Last : RFLX_Types.Bit_Length := RFLX_Types.Bit_Length'First) is private with
     Default_Initial_Condition =>
       RFLX_Types.To_Index (First) >= Buffer_First
       and RFLX_Types.To_Index (Last) <= Buffer_Last
       and Buffer_Last < RFLX_Types.Index'Last
       and First <= Last + 1
       and Last < RFLX_Types.Bit_Index'Last
       and First rem RFLX_Types.Byte'Size = 1
       and Last rem RFLX_Types.Byte'Size = 0;

   procedure Initialize (Ctx : out Context; Buffer : in out RFLX_Types.Bytes_Ptr; Written_Last : RFLX_Types.Bit_Length := 0) with
     Pre =>
       not Ctx'Constrained
       and then Buffer /= null
       and then Buffer'Length > 0
       and then Buffer'Last < RFLX_Types.Index'Last
       and then (Written_Last = 0
                 or (Written_Last >= RFLX_Types.To_First_Bit_Index (Buffer'First) - 1
                     and Written_Last <= RFLX_Types.To_Last_Bit_Index (Buffer'Last)))
       and then Written_Last mod RFLX_Types.Byte'Size = 0,
     Post =>
       Has_Buffer (Ctx)
       and Buffer = null
       and Ctx.Buffer_First = Buffer'First'Old
       and Ctx.Buffer_Last = Buffer'Last'Old
       and Ctx.First = RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First)
       and Ctx.Last = RFLX_Types.To_Last_Bit_Index (Ctx.Buffer_Last)
       and Initialized (Ctx),
     Depends =>
       (Ctx => (Buffer, Written_Last), Buffer => null);

   procedure Initialize (Ctx : out Context; Buffer : in out RFLX_Types.Bytes_Ptr; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length := 0) with
     Pre =>
       not Ctx'Constrained
       and then Buffer /= null
       and then Buffer'Length > 0
       and then Buffer'Last < RFLX_Types.Index'Last
       and then RFLX_Types.To_Index (First) >= Buffer'First
       and then RFLX_Types.To_Index (Last) <= Buffer'Last
       and then First <= Last + 1
       and then Last < RFLX_Types.Bit_Index'Last
       and then First rem RFLX_Types.Byte'Size = 1
       and then Last rem RFLX_Types.Byte'Size = 0
       and then (Written_Last = 0
                 or (Written_Last >= First - 1
                     and Written_Last <= Last))
       and then Written_Last rem RFLX_Types.Byte'Size = 0,
     Post =>
       Buffer = null
       and Has_Buffer (Ctx)
       and Ctx.Buffer_First = Buffer'First'Old
       and Ctx.Buffer_Last = Buffer'Last'Old
       and Ctx.First = First
       and Ctx.Last = Last
       and Initialized (Ctx),
     Depends =>
       (Ctx => (Buffer, First, Last, Written_Last), Buffer => null);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Initialized (Ctx : Context) return Boolean with
     Ghost,
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   procedure Reset (Ctx : in out Context) with
     Pre =>
       not Ctx'Constrained
       and RFLX.Ethernet.Frame.Has_Buffer (Ctx),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First)
       and Ctx.Last = RFLX_Types.To_Last_Bit_Index (Ctx.Buffer_Last)
       and Initialized (Ctx);

   procedure Reset (Ctx : in out Context; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length) with
     Pre =>
       not Ctx'Constrained
       and RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and RFLX_Types.To_Index (First) >= Ctx.Buffer_First
       and RFLX_Types.To_Index (Last) <= Ctx.Buffer_Last
       and First <= Last + 1
       and Last < RFLX_Types.Bit_Length'Last
       and First rem RFLX_Types.Byte'Size = 1
       and Last rem RFLX_Types.Byte'Size = 0,
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = First
       and Ctx.Last = Last
       and Initialized (Ctx);

   procedure Take_Buffer (Ctx : in out Context; Buffer : out RFLX_Types.Bytes_Ptr) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx),
     Post =>
       not Has_Buffer (Ctx)
       and Buffer /= null
       and Ctx.Buffer_First = Buffer'First
       and Ctx.Buffer_Last = Buffer'Last
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Context_Cursors (Ctx) = Context_Cursors (Ctx)'Old,
     Depends =>
       (Ctx => Ctx, Buffer => Ctx);

   procedure Copy (Ctx : Context; Buffer : out RFLX_Types.Bytes) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid_Message (Ctx)
       and then RFLX.Ethernet.Frame.Byte_Size (Ctx) = Buffer'Length;

   function Read (Ctx : Context) return RFLX_Types.Bytes with
     Ghost,
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid_Message (Ctx);

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   function Always_Valid (Buffer : RFLX_Types.Bytes) return Boolean is
     (True);

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   generic
      with procedure Read (Buffer : RFLX_Types.Bytes);
      with function Pre (Buffer : RFLX_Types.Bytes) return Boolean is Always_Valid;
   procedure Generic_Read (Ctx : Context) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid_Message (Ctx)
       and then Pre (Read (Ctx));

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   function Always_Valid (Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length) return Boolean is
     (True);

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   generic
      with procedure Write (Buffer : out RFLX_Types.Bytes; Length : out RFLX_Types.Length; Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length);
      with function Pre (Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length) return Boolean is Always_Valid;
   procedure Generic_Write (Ctx : in out Context; Offset : RFLX_Types.Length := 0) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then Offset < RFLX.Ethernet.Frame.Buffer_Length (Ctx)
       and then Pre (RFLX.Ethernet.Frame.Buffer_Length (Ctx), Offset),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First)
       and Initialized (Ctx);

   function Has_Buffer (Ctx : Context) return Boolean;

   function Buffer_Length (Ctx : Context) return RFLX_Types.Length with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx);

   function Size (Ctx : Context) return RFLX_Types.Bit_Length with
     Post =>
       Size'Result rem RFLX_Types.Byte'Size = 0;

   function Byte_Size (Ctx : Context) return RFLX_Types.Length;

   function Message_Last (Ctx : Context) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid_Message (Ctx);

   function Written_Last (Ctx : Context) return RFLX_Types.Bit_Length;

   procedure Data (Ctx : Context; Data : out RFLX_Types.Bytes) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid_Message (Ctx)
       and then Data'Length = RFLX.Ethernet.Frame.Byte_Size (Ctx);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Value (Fld : Field; Val : RFLX_Types.Base_Integer) return Boolean with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Path_Condition (Ctx : Context; Fld : Field) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Predecessor (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Field_Condition (Ctx : Context; Fld : Field; Val : RFLX_Types.Base_Integer; Size : RFLX_Types.Bit_Length := 0) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Predecessor (Ctx, Fld)
       and then RFLX.Ethernet.Frame.Valid_Value (Fld, Val)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, Fld) >= RFLX.Ethernet.Frame.Field_Size (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   function Field_Size (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld),
     Post =>
       (case Fld is
           when F_Payload =>
              Field_Size'Result rem RFLX_Types.Byte'Size = 0,
           when others =>
              True);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Field_First (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Index with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   function Field_Last (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, Fld) >= RFLX.Ethernet.Frame.Field_Size (Ctx, Fld),
     Post =>
       (case Fld is
           when F_Payload =>
              Field_Last'Result rem RFLX_Types.Byte'Size = 0,
           when others =>
              True);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Predecessor (Ctx : Context; Fld : Virtual_Field) return Virtual_Field with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Predecessor (Ctx : Context; Fld : Virtual_Field) return Boolean with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   function Valid_Next (Ctx : Context; Fld : Field) return Boolean;

   function Available_Space (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld);

   function Equal (Ctx : Context; Fld : Field; Data : RFLX_Types.Bytes) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld);

   procedure Verify (Ctx : in out Context; Fld : Field) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old;

   procedure Verify_Message (Ctx : in out Context) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old;

   function Present (Ctx : Context; Fld : Field) return Boolean;

   function Structural_Valid (Ctx : Context; Fld : Field) return Boolean;

   function Valid (Ctx : Context; Fld : Field) return Boolean with
     Post =>
       (if Valid'Result then Structural_Valid (Ctx, Fld) and Present (Ctx, Fld));

   function Incomplete (Ctx : Context; Fld : Field) return Boolean;

   function Invalid (Ctx : Context; Fld : Field) return Boolean;

   function Structural_Valid_Message (Ctx : Context) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx);

   function Valid_Message (Ctx : Context) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Incomplete_Message (Ctx : Context) return Boolean with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "precondition is always False");

   function Get_Destination (Ctx : Context) return RFLX.Ethernet.Address with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_Destination);

   function Get_Source (Ctx : Context) return RFLX.Ethernet.Address with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_Source);

   function Get_Type_Length_TPID (Ctx : Context) return RFLX.Ethernet.Type_Length with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_Type_Length_TPID);

   function Get_TPID (Ctx : Context) return RFLX.Ethernet.TPID with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_TPID);

   function Get_TCI (Ctx : Context) return RFLX.Ethernet.TCI with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_TCI);

   function Get_Type_Length (Ctx : Context) return RFLX.Ethernet.Type_Length with
     Pre =>
       RFLX.Ethernet.Frame.Valid (Ctx, RFLX.Ethernet.Frame.F_Type_Length);

   pragma Warnings (On, "precondition is always False");

   function Get_Payload (Ctx : Context) return RFLX_Types.Bytes with
     Ghost,
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Payload),
     Post =>
       Get_Payload'Result'Length = RFLX_Types.To_Length (Field_Size (Ctx, F_Payload));

   procedure Get_Payload (Ctx : Context; Data : out RFLX_Types.Bytes) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Structural_Valid (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then Data'Length = RFLX_Types.To_Length (RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Payload)),
     Post =>
       Equal (Ctx, F_Payload, Data);

   generic
      with procedure Process_Payload (Payload : RFLX_Types.Bytes);
   procedure Generic_Get_Payload (Ctx : Context) with
     Pre =>
       RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and RFLX.Ethernet.Frame.Present (Ctx, RFLX.Ethernet.Frame.F_Payload);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Length (Ctx : Context; Fld : Field; Length : RFLX_Types.Length) return Boolean with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "aspect ""*"" not enforced on inlined subprogram ""*""");

   procedure Set_Destination (Ctx : in out Context; Val : RFLX.Ethernet.Address) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Destination)
       and then RFLX.Ethernet.Valid_Address (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Destination) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Destination)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_Destination, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Destination)
       and Get_Destination (Ctx) = Val
       and Invalid (Ctx, F_Source)
       and Invalid (Ctx, F_Type_Length_TPID)
       and Invalid (Ctx, F_TPID)
       and Invalid (Ctx, F_TCI)
       and Invalid (Ctx, F_Type_Length)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Source) = F_Destination
            and Valid_Next (Ctx, F_Source))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Destination) = Predecessor (Ctx, F_Destination)'Old
       and Valid_Next (Ctx, F_Destination) = Valid_Next (Ctx, F_Destination)'Old
       and Field_First (Ctx, F_Destination) = Field_First (Ctx, F_Destination)'Old;

   procedure Set_Source (Ctx : in out Context; Val : RFLX.Ethernet.Address) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Source)
       and then RFLX.Ethernet.Valid_Address (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Source) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Source)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_Source, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Source)
       and Get_Source (Ctx) = Val
       and Invalid (Ctx, F_Type_Length_TPID)
       and Invalid (Ctx, F_TPID)
       and Invalid (Ctx, F_TCI)
       and Invalid (Ctx, F_Type_Length)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Type_Length_TPID) = F_Source
            and Valid_Next (Ctx, F_Type_Length_TPID))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Source) = Predecessor (Ctx, F_Source)'Old
       and Valid_Next (Ctx, F_Source) = Valid_Next (Ctx, F_Source)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Field_First (Ctx, F_Source) = Field_First (Ctx, F_Source)'Old
       and Field_Last (Ctx, F_Source) = Field_Last (Ctx, Predecessor (Ctx, F_Source)) + Field_Size (Ctx, F_Source)
       and (for all F in Field range F_Destination .. F_Destination =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_Type_Length_TPID (Ctx : in out Context; Val : RFLX.Ethernet.Type_Length) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Type_Length_TPID)
       and then RFLX.Ethernet.Valid_Type_Length (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Type_Length_TPID) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Type_Length_TPID)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_Type_Length_TPID, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Type_Length_TPID)
       and Get_Type_Length_TPID (Ctx) = Val
       and Invalid (Ctx, F_TPID)
       and Invalid (Ctx, F_TCI)
       and Invalid (Ctx, F_Type_Length)
       and Invalid (Ctx, F_Payload)
       and (if
               Get_Type_Length_TPID (Ctx) = 16#8100#
            then
               Predecessor (Ctx, F_TPID) = F_Type_Length_TPID
               and Valid_Next (Ctx, F_TPID))
       and (if
               Get_Type_Length_TPID (Ctx) /= 16#8100#
            then
               Predecessor (Ctx, F_Type_Length) = F_Type_Length_TPID
               and Valid_Next (Ctx, F_Type_Length))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Type_Length_TPID) = Predecessor (Ctx, F_Type_Length_TPID)'Old
       and Valid_Next (Ctx, F_Type_Length_TPID) = Valid_Next (Ctx, F_Type_Length_TPID)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Field_First (Ctx, F_Type_Length_TPID) = Field_First (Ctx, F_Type_Length_TPID)'Old
       and Field_Last (Ctx, F_Type_Length_TPID) = Field_Last (Ctx, Predecessor (Ctx, F_Type_Length_TPID)) + Field_Size (Ctx, F_Type_Length_TPID)
       and (for all F in Field range F_Destination .. F_Source =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_TPID (Ctx : in out Context; Val : RFLX.Ethernet.TPID) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_TPID)
       and then RFLX.Ethernet.Valid_TPID (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_TPID) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_TPID)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_TPID, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_TPID)
       and Invalid (Ctx, F_TCI)
       and Invalid (Ctx, F_Type_Length)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_TCI) = F_TPID
            and Valid_Next (Ctx, F_TCI))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_TPID) = Predecessor (Ctx, F_TPID)'Old
       and Valid_Next (Ctx, F_TPID) = Valid_Next (Ctx, F_TPID)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Field_First (Ctx, F_TPID) = Field_First (Ctx, F_TPID)'Old
       and (for all F in Field range F_Destination .. F_Type_Length_TPID =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_TCI (Ctx : in out Context; Val : RFLX.Ethernet.TCI) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_TCI)
       and then RFLX.Ethernet.Valid_TCI (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_TCI) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_TCI)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_TCI, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_TCI)
       and Get_TCI (Ctx) = Val
       and Invalid (Ctx, F_Type_Length)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Type_Length) = F_TCI
            and Valid_Next (Ctx, F_Type_Length))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_TCI) = Predecessor (Ctx, F_TCI)'Old
       and Valid_Next (Ctx, F_TCI) = Valid_Next (Ctx, F_TCI)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Field_First (Ctx, F_TCI) = Field_First (Ctx, F_TCI)'Old
       and Field_Last (Ctx, F_TCI) = Field_Last (Ctx, Predecessor (Ctx, F_TCI)) + Field_Size (Ctx, F_TCI)
       and (for all F in Field range F_Destination .. F_TPID =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_Type_Length (Ctx : in out Context; Val : RFLX.Ethernet.Type_Length) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Type_Length)
       and then RFLX.Ethernet.Valid_Type_Length (RFLX.Ethernet.To_Base_Integer (Val))
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Type_Length) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Type_Length)
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_Type_Length, RFLX.Ethernet.To_Base_Integer (Val)),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Type_Length)
       and Get_Type_Length (Ctx) = Val
       and Invalid (Ctx, F_Payload)
       and (if
               Get_Type_Length (Ctx) <= 1500
            then
               Predecessor (Ctx, F_Payload) = F_Type_Length
               and Valid_Next (Ctx, F_Payload))
       and (if
               Get_Type_Length (Ctx) >= 1536
            then
               Predecessor (Ctx, F_Payload) = F_Type_Length
               and Valid_Next (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Type_Length) = Predecessor (Ctx, F_Type_Length)'Old
       and Valid_Next (Ctx, F_Type_Length) = Valid_Next (Ctx, F_Type_Length)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Field_First (Ctx, F_Type_Length) = Field_First (Ctx, F_Type_Length)'Old
       and (for all F in Field range F_Destination .. F_TCI =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   pragma Warnings (On, "aspect ""*"" not enforced on inlined subprogram ""*""");

   procedure Initialize_Payload (Ctx : in out Context; Length : RFLX_Types.Length) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Valid_Length (Ctx, RFLX.Ethernet.Frame.F_Payload, Length)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Payload) >= RFLX_Types.To_Bit_Length (Length),
     Post =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, F_Payload)
       and Field_Size (Ctx, F_Payload) = RFLX_Types.To_Bit_Length (Length)
       and (if Structural_Valid_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Get_Type_Length (Ctx) = Get_Type_Length (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old
       and Field_Last (Ctx, F_Payload) = Field_Last (Ctx, Predecessor (Ctx, F_Payload)) + Field_Size (Ctx, F_Payload);

   procedure Set_Payload (Ctx : in out Context; Data : RFLX_Types.Bytes) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Payload) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Valid_Length (Ctx, RFLX.Ethernet.Frame.F_Payload, Data'Length)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Payload) >= Data'Length * RFLX_Types.Byte'Size
       and then RFLX.Ethernet.Frame.Field_Condition (Ctx, RFLX.Ethernet.Frame.F_Payload, 0, RFLX_Types.To_Bit_Length (Data'Length)),
     Post =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, F_Payload)
       and (if Structural_Valid_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Get_Type_Length (Ctx) = Get_Type_Length (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old
       and Field_Last (Ctx, F_Payload) = Field_Last (Ctx, Predecessor (Ctx, F_Payload)) + Field_Size (Ctx, F_Payload)
       and Equal (Ctx, F_Payload, Data);

   generic
      with procedure Process_Payload (Payload : out RFLX_Types.Bytes);
      with function Process_Data_Pre (Length : RFLX_Types.Length) return Boolean;
   procedure Generic_Set_Payload (Ctx : in out Context; Length : RFLX_Types.Length) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.Ethernet.Frame.Has_Buffer (Ctx)
       and then RFLX.Ethernet.Frame.Valid_Next (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Payload) >= RFLX.Ethernet.Frame.Field_Size (Ctx, RFLX.Ethernet.Frame.F_Payload)
       and then RFLX.Ethernet.Frame.Valid_Length (Ctx, RFLX.Ethernet.Frame.F_Payload, Length)
       and then RFLX_Types.To_Length (RFLX.Ethernet.Frame.Available_Space (Ctx, RFLX.Ethernet.Frame.F_Payload)) >= Length
       and then Process_Data_Pre (Length),
     Post =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, F_Payload)
       and (if Structural_Valid_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Destination (Ctx) = Get_Destination (Ctx)'Old
       and Get_Source (Ctx) = Get_Source (Ctx)'Old
       and Get_Type_Length_TPID (Ctx) = Get_Type_Length_TPID (Ctx)'Old
       and Get_Type_Length (Ctx) = Get_Type_Length (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old
       and Field_Last (Ctx, F_Payload) = Field_Last (Ctx, Predecessor (Ctx, F_Payload)) + Field_Size (Ctx, F_Payload);

   function Context_Cursor (Ctx : Context; Fld : Field) return Field_Cursor with
     Annotate =>
       (GNATprove, Inline_For_Proof),
     Ghost;

   function Context_Cursors (Ctx : Context) return Field_Cursors with
     Annotate =>
       (GNATprove, Inline_For_Proof),
     Ghost;

   function Context_Cursors_Index (Cursors : Field_Cursors; Fld : Field) return Field_Cursor with
     Annotate =>
       (GNATprove, Inline_For_Proof),
     Ghost;

private

   type Cursor_State is (S_Valid, S_Structural_Valid, S_Invalid, S_Incomplete);

   type Field_Cursor (State : Cursor_State := S_Invalid) is
      record
         Predecessor : Virtual_Field := F_Final;
         case State is
            when S_Valid | S_Structural_Valid =>
               First : RFLX_Types.Bit_Index := RFLX_Types.Bit_Index'First;
               Last : RFLX_Types.Bit_Length := RFLX_Types.Bit_Length'First;
               Value : RFLX_Types.Base_Integer := 0;
            when S_Invalid | S_Incomplete =>
               null;
         end case;
      end record;

   type Field_Cursors is array (Virtual_Field) of Field_Cursor;

   function Structural_Valid (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Valid
      or Cursor.State = S_Structural_Valid);

   function Valid (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Valid);

   function Invalid (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Invalid
      or Cursor.State = S_Incomplete);

   pragma Warnings (Off, """Buffer"" is not modified, could be of access constant type");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Context (Buffer_First, Buffer_Last : RFLX_Types.Index; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length; Verified_Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length; Buffer : RFLX_Types.Bytes_Ptr; Cursors : Field_Cursors) return Boolean is
     ((if Buffer /= null then Buffer'First = Buffer_First and Buffer'Last = Buffer_Last)
      and then (RFLX_Types.To_Index (First) >= Buffer_First
                and RFLX_Types.To_Index (Last) <= Buffer_Last
                and Buffer_Last < RFLX_Types.Index'Last
                and First <= Last + 1
                and Last < RFLX_Types.Bit_Index'Last
                and First rem RFLX_Types.Byte'Size = 1
                and Last rem RFLX_Types.Byte'Size = 0)
      and then First - 1 <= Verified_Last
      and then First - 1 <= Written_Last
      and then Verified_Last <= Written_Last
      and then Written_Last <= Last
      and then First rem RFLX_Types.Byte'Size = 1
      and then Last rem RFLX_Types.Byte'Size = 0
      and then Verified_Last rem RFLX_Types.Byte'Size = 0
      and then Written_Last rem RFLX_Types.Byte'Size = 0
      and then (for all F in Field =>
                   (if
                       Structural_Valid (Cursors (F))
                    then
                       Cursors (F).First >= First
                       and Cursors (F).Last <= Verified_Last
                       and Cursors (F).First <= Cursors (F).Last + 1
                       and Valid_Value (F, Cursors (F).Value)))
      and then ((if
                    Structural_Valid (Cursors (F_Source))
                 then
                    (Valid (Cursors (F_Destination))
                     and then Cursors (F_Source).Predecessor = F_Destination))
                and then (if
                             Structural_Valid (Cursors (F_Type_Length_TPID))
                          then
                             (Valid (Cursors (F_Source))
                              and then Cursors (F_Type_Length_TPID).Predecessor = F_Source))
                and then (if
                             Structural_Valid (Cursors (F_TPID))
                          then
                             (Valid (Cursors (F_Type_Length_TPID))
                              and then Cursors (F_TPID).Predecessor = F_Type_Length_TPID
                              and then Cursors (F_Type_Length_TPID).Value = 16#8100#))
                and then (if
                             Structural_Valid (Cursors (F_TCI))
                          then
                             (Valid (Cursors (F_TPID))
                              and then Cursors (F_TCI).Predecessor = F_TPID))
                and then (if
                             Structural_Valid (Cursors (F_Type_Length))
                          then
                             (Valid (Cursors (F_TCI))
                              and then Cursors (F_Type_Length).Predecessor = F_TCI)
                             or (Valid (Cursors (F_Type_Length_TPID))
                                 and then Cursors (F_Type_Length).Predecessor = F_Type_Length_TPID
                                 and then Cursors (F_Type_Length_TPID).Value /= 16#8100#))
                and then (if
                             Structural_Valid (Cursors (F_Payload))
                          then
                             (Valid (Cursors (F_Type_Length))
                              and then Cursors (F_Payload).Predecessor = F_Type_Length
                              and then Cursors (F_Type_Length).Value <= 1500)
                             or (Valid (Cursors (F_Type_Length))
                                 and then Cursors (F_Payload).Predecessor = F_Type_Length
                                 and then Cursors (F_Type_Length).Value >= 1536)))
      and then ((if Invalid (Cursors (F_Destination)) then Invalid (Cursors (F_Source)))
                and then (if Invalid (Cursors (F_Source)) then Invalid (Cursors (F_Type_Length_TPID)))
                and then (if Invalid (Cursors (F_Type_Length_TPID)) then Invalid (Cursors (F_TPID)))
                and then (if Invalid (Cursors (F_TPID)) then Invalid (Cursors (F_TCI)))
                and then (if
                             Invalid (Cursors (F_TCI))
                             and then Invalid (Cursors (F_Type_Length_TPID))
                          then
                             Invalid (Cursors (F_Type_Length)))
                and then (if Invalid (Cursors (F_Type_Length)) then Invalid (Cursors (F_Payload))))
      and then (if
                   Structural_Valid (Cursors (F_Destination))
                then
                   Cursors (F_Destination).Last - Cursors (F_Destination).First + 1 = 48
                   and then Cursors (F_Destination).Predecessor = F_Initial
                   and then Cursors (F_Destination).First = First
                   and then (if
                                Structural_Valid (Cursors (F_Source))
                             then
                                Cursors (F_Source).Last - Cursors (F_Source).First + 1 = 48
                                and then Cursors (F_Source).Predecessor = F_Destination
                                and then Cursors (F_Source).First = Cursors (F_Destination).Last + 1
                                and then (if
                                             Structural_Valid (Cursors (F_Type_Length_TPID))
                                          then
                                             Cursors (F_Type_Length_TPID).Last - Cursors (F_Type_Length_TPID).First + 1 = 16
                                             and then Cursors (F_Type_Length_TPID).Predecessor = F_Source
                                             and then Cursors (F_Type_Length_TPID).First = Cursors (F_Source).Last + 1
                                             and then (if
                                                          Structural_Valid (Cursors (F_TPID))
                                                          and then Cursors (F_Type_Length_TPID).Value = 16#8100#
                                                       then
                                                          Cursors (F_TPID).Last - Cursors (F_TPID).First + 1 = 16
                                                          and then Cursors (F_TPID).Predecessor = F_Type_Length_TPID
                                                          and then Cursors (F_TPID).First = RFLX_Types.Bit_Index (Cursors (F_Type_Length_TPID).First)
                                                          and then (if
                                                                       Structural_Valid (Cursors (F_TCI))
                                                                    then
                                                                       Cursors (F_TCI).Last - Cursors (F_TCI).First + 1 = 16
                                                                       and then Cursors (F_TCI).Predecessor = F_TPID
                                                                       and then Cursors (F_TCI).First = Cursors (F_TPID).Last + 1
                                                                       and then (if
                                                                                    Structural_Valid (Cursors (F_Type_Length))
                                                                                 then
                                                                                    Cursors (F_Type_Length).Last - Cursors (F_Type_Length).First + 1 = 16
                                                                                    and then Cursors (F_Type_Length).Predecessor = F_TCI
                                                                                    and then Cursors (F_Type_Length).First = Cursors (F_TCI).Last + 1
                                                                                    and then (if
                                                                                                 Structural_Valid (Cursors (F_Payload))
                                                                                                 and then Cursors (F_Type_Length).Value <= 1500
                                                                                              then
                                                                                                 Cursors (F_Payload).Last - Cursors (F_Payload).First + 1 = RFLX_Types.Bit_Length (Cursors (F_Type_Length).Value) * 8
                                                                                                 and then Cursors (F_Payload).Predecessor = F_Type_Length
                                                                                                 and then Cursors (F_Payload).First = Cursors (F_Type_Length).Last + 1)
                                                                                    and then (if
                                                                                                 Structural_Valid (Cursors (F_Payload))
                                                                                                 and then Cursors (F_Type_Length).Value >= 1536
                                                                                              then
                                                                                                 Cursors (F_Payload).Last - Cursors (F_Payload).First + 1 = RFLX_Types.Bit_Length (Written_Last) - RFLX_Types.Bit_Length (Cursors (F_Type_Length).Last)
                                                                                                 and then Cursors (F_Payload).Predecessor = F_Type_Length
                                                                                                 and then Cursors (F_Payload).First = Cursors (F_Type_Length).Last + 1))))
                                             and then (if
                                                          Structural_Valid (Cursors (F_Type_Length))
                                                          and then Cursors (F_Type_Length_TPID).Value /= 16#8100#
                                                       then
                                                          Cursors (F_Type_Length).Last - Cursors (F_Type_Length).First + 1 = 16
                                                          and then Cursors (F_Type_Length).Predecessor = F_Type_Length_TPID
                                                          and then Cursors (F_Type_Length).First = RFLX_Types.Bit_Index (Cursors (F_Type_Length_TPID).First)
                                                          and then (if
                                                                       Structural_Valid (Cursors (F_Payload))
                                                                       and then Cursors (F_Type_Length).Value <= 1500
                                                                    then
                                                                       Cursors (F_Payload).Last - Cursors (F_Payload).First + 1 = RFLX_Types.Bit_Length (Cursors (F_Type_Length).Value) * 8
                                                                       and then Cursors (F_Payload).Predecessor = F_Type_Length
                                                                       and then Cursors (F_Payload).First = Cursors (F_Type_Length).Last + 1)
                                                          and then (if
                                                                       Structural_Valid (Cursors (F_Payload))
                                                                       and then Cursors (F_Type_Length).Value >= 1536
                                                                    then
                                                                       Cursors (F_Payload).Last - Cursors (F_Payload).First + 1 = RFLX_Types.Bit_Length (Written_Last) - RFLX_Types.Bit_Length (Cursors (F_Type_Length).Last)
                                                                       and then Cursors (F_Payload).Predecessor = F_Type_Length
                                                                       and then Cursors (F_Payload).First = Cursors (F_Type_Length).Last + 1))))));

   pragma Warnings (On, """Buffer"" is not modified, could be of access constant type");

   pragma Warnings (On, "postcondition does not mention function result");

   type Context (Buffer_First, Buffer_Last : RFLX_Types.Index := RFLX_Types.Index'First; First : RFLX_Types.Bit_Index := RFLX_Types.Bit_Index'First; Last : RFLX_Types.Bit_Length := RFLX_Types.Bit_Length'First) is
      record
         Verified_Last : RFLX_Types.Bit_Length := First - 1;
         Written_Last : RFLX_Types.Bit_Length := First - 1;
         Buffer : RFLX_Types.Bytes_Ptr := null;
         Cursors : Field_Cursors := (others => (State => S_Invalid, Predecessor => F_Final));
      end record with
     Dynamic_Predicate =>
       Valid_Context (Context.Buffer_First, Context.Buffer_Last, Context.First, Context.Last, Context.Verified_Last, Context.Written_Last, Context.Buffer, Context.Cursors);

   function Initialized (Ctx : Context) return Boolean is
     (Ctx.Verified_Last = Ctx.First - 1
      and then Valid_Next (Ctx, F_Destination)
      and then RFLX.Ethernet.Frame.Field_First (Ctx, RFLX.Ethernet.Frame.F_Destination) rem RFLX_Types.Byte'Size = 1
      and then Available_Space (Ctx, F_Destination) = Ctx.Last - Ctx.First + 1
      and then (for all F in Field =>
                   Invalid (Ctx, F)));

   function Has_Buffer (Ctx : Context) return Boolean is
     (Ctx.Buffer /= null);

   function Buffer_Length (Ctx : Context) return RFLX_Types.Length is
     (Ctx.Buffer'Length);

   function Size (Ctx : Context) return RFLX_Types.Bit_Length is
     (Ctx.Verified_Last - Ctx.First + 1);

   function Byte_Size (Ctx : Context) return RFLX_Types.Length is
     (RFLX_Types.To_Length (Size (Ctx)));

   function Message_Last (Ctx : Context) return RFLX_Types.Bit_Length is
     (Ctx.Verified_Last);

   function Written_Last (Ctx : Context) return RFLX_Types.Bit_Length is
     (Ctx.Written_Last);

   function Valid_Value (Fld : Field; Val : RFLX_Types.Base_Integer) return Boolean is
     ((case Fld is
          when F_Destination | F_Source =>
             RFLX.Ethernet.Valid_Address (Val),
          when F_Type_Length_TPID =>
             RFLX.Ethernet.Valid_Type_Length (Val),
          when F_TPID =>
             RFLX.Ethernet.Valid_TPID (Val),
          when F_TCI =>
             RFLX.Ethernet.Valid_TCI (Val),
          when F_Type_Length =>
             RFLX.Ethernet.Valid_Type_Length (Val),
          when F_Payload =>
             True));

   function Path_Condition (Ctx : Context; Fld : Field) return Boolean is
     ((case Ctx.Cursors (Fld).Predecessor is
          when F_Initial | F_Destination | F_Source | F_TPID | F_TCI | F_Payload | F_Final =>
             True,
          when F_Type_Length_TPID =>
             (case Fld is
                 when F_TPID =>
                    Ctx.Cursors (F_Type_Length_TPID).Value = 16#8100#,
                 when F_Type_Length =>
                    Ctx.Cursors (F_Type_Length_TPID).Value /= 16#8100#,
                 when others =>
                    False),
          when F_Type_Length =>
             (case Fld is
                 when F_Payload =>
                    Ctx.Cursors (F_Type_Length).Value <= 1500
                    or Ctx.Cursors (F_Type_Length).Value >= 1536,
                 when others =>
                    False)));

   function Field_Condition (Ctx : Context; Fld : Field; Val : RFLX_Types.Base_Integer; Size : RFLX_Types.Bit_Length := 0) return Boolean is
     ((case Fld is
          when F_Destination | F_Source =>
             True,
          when F_Type_Length_TPID =>
             Val = 16#8100#
             or Val /= 16#8100#,
          when F_TPID | F_TCI =>
             True,
          when F_Type_Length =>
             Val <= 1500
             or Val >= 1536,
          when F_Payload =>
             RFLX_Types.Base_Integer (Size) / 8 >= 46
             and RFLX_Types.Base_Integer (Size) / 8 <= 1500));

   function Field_Size (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     ((case Fld is
          when F_Destination | F_Source =>
             48,
          when F_Type_Length_TPID | F_TPID | F_TCI | F_Type_Length =>
             16,
          when F_Payload =>
             (if
                 Ctx.Cursors (Fld).Predecessor = F_Type_Length
                 and then Ctx.Cursors (F_Type_Length).Value <= 1500
              then
                 RFLX_Types.Bit_Length (Ctx.Cursors (F_Type_Length).Value) * 8
              elsif
                 Ctx.Cursors (Fld).Predecessor = F_Type_Length
                 and then Ctx.Cursors (F_Type_Length).Value >= 1536
              then
                 RFLX_Types.Bit_Length (Ctx.Written_Last) - RFLX_Types.Bit_Length (Ctx.Cursors (F_Type_Length).Last)
              else
                 RFLX_Types.Unreachable)));

   function Field_First (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Index is
     ((if
          Fld = F_Destination
       then
          Ctx.First
       elsif
          Fld = F_TPID
          and then Ctx.Cursors (Fld).Predecessor = F_Type_Length_TPID
          and then Ctx.Cursors (F_Type_Length_TPID).Value = 16#8100#
       then
          Ctx.Cursors (F_Type_Length_TPID).First
       elsif
          Fld = F_Type_Length
          and then Ctx.Cursors (Fld).Predecessor = F_Type_Length_TPID
          and then Ctx.Cursors (F_Type_Length_TPID).Value /= 16#8100#
       then
          Ctx.Cursors (F_Type_Length_TPID).First
       else
          Ctx.Cursors (Ctx.Cursors (Fld).Predecessor).Last + 1));

   function Field_Last (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     (Field_First (Ctx, Fld) + Field_Size (Ctx, Fld) - 1);

   function Predecessor (Ctx : Context; Fld : Virtual_Field) return Virtual_Field is
     ((case Fld is
          when F_Initial =>
             F_Initial,
          when others =>
             Ctx.Cursors (Fld).Predecessor));

   function Valid_Predecessor (Ctx : Context; Fld : Virtual_Field) return Boolean is
     ((case Fld is
          when F_Initial =>
             True,
          when F_Destination =>
             Ctx.Cursors (Fld).Predecessor = F_Initial,
          when F_Source =>
             (Valid (Ctx.Cursors (F_Destination))
              and Ctx.Cursors (Fld).Predecessor = F_Destination),
          when F_Type_Length_TPID =>
             (Valid (Ctx.Cursors (F_Source))
              and Ctx.Cursors (Fld).Predecessor = F_Source),
          when F_TPID =>
             (Valid (Ctx.Cursors (F_Type_Length_TPID))
              and Ctx.Cursors (Fld).Predecessor = F_Type_Length_TPID),
          when F_TCI =>
             (Valid (Ctx.Cursors (F_TPID))
              and Ctx.Cursors (Fld).Predecessor = F_TPID),
          when F_Type_Length =>
             (Valid (Ctx.Cursors (F_TCI))
              and Ctx.Cursors (Fld).Predecessor = F_TCI)
             or (Valid (Ctx.Cursors (F_Type_Length_TPID))
                 and Ctx.Cursors (Fld).Predecessor = F_Type_Length_TPID),
          when F_Payload =>
             (Valid (Ctx.Cursors (F_Type_Length))
              and Ctx.Cursors (Fld).Predecessor = F_Type_Length),
          when F_Final =>
             (Structural_Valid (Ctx.Cursors (F_Payload))
              and Ctx.Cursors (Fld).Predecessor = F_Payload)));

   function Valid_Next (Ctx : Context; Fld : Field) return Boolean is
     (Valid_Predecessor (Ctx, Fld)
      and then Path_Condition (Ctx, Fld));

   function Available_Space (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     (Ctx.Last - Field_First (Ctx, Fld) + 1);

   function Present (Ctx : Context; Fld : Field) return Boolean is
     (Structural_Valid (Ctx.Cursors (Fld))
      and then Ctx.Cursors (Fld).First < Ctx.Cursors (Fld).Last + 1);

   function Structural_Valid (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Valid
      or Ctx.Cursors (Fld).State = S_Structural_Valid);

   function Valid (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Valid
      and then Ctx.Cursors (Fld).First < Ctx.Cursors (Fld).Last + 1);

   function Incomplete (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Incomplete);

   function Invalid (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Invalid
      or Ctx.Cursors (Fld).State = S_Incomplete);

   function Structural_Valid_Message (Ctx : Context) return Boolean is
     (Structural_Valid (Ctx, F_Payload)
      and then (RFLX_Types.Base_Integer (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 >= 46
                and RFLX_Types.Base_Integer (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 <= 1500));

   function Valid_Message (Ctx : Context) return Boolean is
     (Valid (Ctx, F_Payload)
      and then (RFLX_Types.Base_Integer (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 >= 46
                and RFLX_Types.Base_Integer (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 <= 1500));

   function Incomplete_Message (Ctx : Context) return Boolean is
     ((for some F in Field =>
          Incomplete (Ctx, F)));

   function Get_Destination (Ctx : Context) return RFLX.Ethernet.Address is
     (To_Actual (Ctx.Cursors (F_Destination).Value));

   function Get_Source (Ctx : Context) return RFLX.Ethernet.Address is
     (To_Actual (Ctx.Cursors (F_Source).Value));

   function Get_Type_Length_TPID (Ctx : Context) return RFLX.Ethernet.Type_Length is
     (To_Actual (Ctx.Cursors (F_Type_Length_TPID).Value));

   function Get_TPID (Ctx : Context) return RFLX.Ethernet.TPID is
     (To_Actual (Ctx.Cursors (F_TPID).Value));

   function Get_TCI (Ctx : Context) return RFLX.Ethernet.TCI is
     (To_Actual (Ctx.Cursors (F_TCI).Value));

   function Get_Type_Length (Ctx : Context) return RFLX.Ethernet.Type_Length is
     (To_Actual (Ctx.Cursors (F_Type_Length).Value));

   function Valid_Size (Ctx : Context; Fld : Field; Size : RFLX_Types.Bit_Length) return Boolean is
     ((if
          Fld = F_Payload
          and then Ctx.Cursors (Fld).Predecessor = F_Type_Length
          and then Ctx.Cursors (F_Type_Length).Value >= 1536
       then
          Size <= Available_Space (Ctx, Fld)
       else
          Size = Field_Size (Ctx, Fld)))
    with
     Pre =>
       RFLX.Ethernet.Frame.Valid_Next (Ctx, Fld);

   function Valid_Length (Ctx : Context; Fld : Field; Length : RFLX_Types.Length) return Boolean is
     (Valid_Size (Ctx, Fld, RFLX_Types.To_Bit_Length (Length)));

   function Context_Cursor (Ctx : Context; Fld : Field) return Field_Cursor is
     (Ctx.Cursors (Fld));

   function Context_Cursors (Ctx : Context) return Field_Cursors is
     (Ctx.Cursors);

   function Context_Cursors_Index (Cursors : Field_Cursors; Fld : Field) return Field_Cursor is
     (Cursors (Fld));

end RFLX.Ethernet.Frame;
