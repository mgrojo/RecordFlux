pragma Style_Checks ("N3aAbCdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");
with RFLX.RFLX_Types;

package RFLX.UDP.Datagram with
  SPARK_Mode,
  Always_Terminates
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

   type Virtual_Field is (F_Initial, F_Source_Port, F_Destination_Port, F_Length, F_Checksum, F_Payload, F_Final);

   subtype Field is Virtual_Field range F_Source_Port .. F_Payload;

   type Field_Cursor is private;

   type Field_Cursors is private;

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
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   procedure Reset (Ctx : in out Context) with
     Pre =>
       not Ctx'Constrained
       and RFLX.UDP.Datagram.Has_Buffer (Ctx),
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
       and RFLX.UDP.Datagram.Has_Buffer (Ctx)
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
       RFLX.UDP.Datagram.Has_Buffer (Ctx),
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
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx)
       and then RFLX.UDP.Datagram.Byte_Size (Ctx) = Buffer'Length;

   function Read (Ctx : Context) return RFLX_Types.Bytes with
     Ghost,
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx);

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   pragma Warnings (Off, "unused variable ""*""");

   function Always_Valid (Buffer : RFLX_Types.Bytes) return Boolean is
     (True);

   pragma Warnings (On, "unused variable ""*""");

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   generic
      with procedure Read (Buffer : RFLX_Types.Bytes);
      with function Pre (Buffer : RFLX_Types.Bytes) return Boolean is Always_Valid;
   procedure Generic_Read (Ctx : Context) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx)
       and then Pre (Read (Ctx));

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   pragma Warnings (Off, "unused variable ""*""");

   function Always_Valid (Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length) return Boolean is
     (True);

   pragma Warnings (On, "unused variable ""*""");

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   generic
      with procedure Write (Buffer : out RFLX_Types.Bytes; Length : out RFLX_Types.Length; Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length);
      with function Pre (Context_Buffer_Length : RFLX_Types.Length; Offset : RFLX_Types.Length) return Boolean is Always_Valid;
   procedure Generic_Write (Ctx : in out Context; Offset : RFLX_Types.Length := 0) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then Offset < RFLX.UDP.Datagram.Buffer_Length (Ctx)
       and then Pre (RFLX.UDP.Datagram.Buffer_Length (Ctx), Offset),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First)
       and Initialized (Ctx);

   function Has_Buffer (Ctx : Context) return Boolean;

   function Buffer_Length (Ctx : Context) return RFLX_Types.Length with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx);

   function Size (Ctx : Context) return RFLX_Types.Bit_Length with
     Post =>
       Size'Result rem RFLX_Types.Byte'Size = 0;

   function Byte_Size (Ctx : Context) return RFLX_Types.Length;

   function Message_Last (Ctx : Context) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx);

   function Written_Last (Ctx : Context) return RFLX_Types.Bit_Length;

   procedure Data (Ctx : Context; Data : out RFLX_Types.Bytes) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx)
       and then Data'Length = RFLX.UDP.Datagram.Byte_Size (Ctx);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Value (Fld : Field; Val : RFLX_Types.Base_Integer) return Boolean with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Field_Condition (Ctx : Context; Fld : Field) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, Fld)
       and then RFLX.UDP.Datagram.Sufficient_Space (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   function Field_Size (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld),
     Post =>
       (case Fld is
           when F_Payload =>
              Field_Size'Result rem RFLX_Types.Byte'Size = 0,
           when others =>
              True);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Field_First (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Index with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   function Field_Last (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld)
       and then RFLX.UDP.Datagram.Sufficient_Space (Ctx, Fld),
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

   function Valid_Next (Ctx : Context; Fld : Field) return Boolean;

   function Available_Space (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld);

   function Sufficient_Space (Ctx : Context; Fld : Field) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld);

   function Equal (Ctx : Context; Fld : Field; Data : RFLX_Types.Bytes) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and RFLX.UDP.Datagram.Valid_Next (Ctx, Fld);

   procedure Verify (Ctx : in out Context; Fld : Field) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old;

   procedure Verify_Message (Ctx : in out Context) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx),
     Post =>
       Has_Buffer (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old;

   function Present (Ctx : Context; Fld : Field) return Boolean;

   function Well_Formed (Ctx : Context; Fld : Field) return Boolean;

   function Valid (Ctx : Context; Fld : Field) return Boolean with
     Post =>
       (if Valid'Result then Well_Formed (Ctx, Fld) and Present (Ctx, Fld));

   function Incomplete (Ctx : Context; Fld : Field) return Boolean;

   function Invalid (Ctx : Context; Fld : Field) return Boolean;

   function Well_Formed_Message (Ctx : Context) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx);

   function Valid_Message (Ctx : Context) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Incomplete_Message (Ctx : Context) return Boolean with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "precondition is always False");

   function Get_Source_Port (Ctx : Context) return RFLX.UDP.Port with
     Pre =>
       RFLX.UDP.Datagram.Valid (Ctx, RFLX.UDP.Datagram.F_Source_Port);

   function Get_Destination_Port (Ctx : Context) return RFLX.UDP.Port with
     Pre =>
       RFLX.UDP.Datagram.Valid (Ctx, RFLX.UDP.Datagram.F_Destination_Port);

   function Get_Length (Ctx : Context) return RFLX.UDP.Length with
     Pre =>
       RFLX.UDP.Datagram.Valid (Ctx, RFLX.UDP.Datagram.F_Length);

   function Get_Checksum (Ctx : Context) return RFLX.UDP.Checksum with
     Pre =>
       RFLX.UDP.Datagram.Valid (Ctx, RFLX.UDP.Datagram.F_Checksum);

   pragma Warnings (On, "precondition is always False");

   function Get_Payload (Ctx : Context) return RFLX_Types.Bytes with
     Ghost,
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload),
     Post =>
       Get_Payload'Result'Length = RFLX_Types.To_Length (Field_Size (Ctx, F_Payload));

   procedure Get_Payload (Ctx : Context; Data : out RFLX_Types.Bytes) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then Data'Length = RFLX_Types.To_Length (RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload)),
     Post =>
       Equal (Ctx, F_Payload, Data);

   generic
      with procedure Process_Payload (Payload : RFLX_Types.Bytes);
   procedure Generic_Get_Payload (Ctx : Context) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and RFLX.UDP.Datagram.Present (Ctx, RFLX.UDP.Datagram.F_Payload);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Length (Ctx : Context; Fld : Field; Length : RFLX_Types.Length) return Boolean with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "aspect ""*"" not enforced on inlined subprogram ""*""");

   procedure Set_Source_Port (Ctx : in out Context; Val : RFLX.UDP.Port) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Source_Port)
       and then RFLX.UDP.Valid_Port (RFLX.UDP.To_Base_Integer (Val))
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Source_Port) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Source_Port)
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Source_Port),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Source_Port)
       and Get_Source_Port (Ctx) = Val
       and Invalid (Ctx, F_Destination_Port)
       and Invalid (Ctx, F_Length)
       and Invalid (Ctx, F_Checksum)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Destination_Port) = F_Source_Port
            and Valid_Next (Ctx, F_Destination_Port))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Source_Port) = Predecessor (Ctx, F_Source_Port)'Old
       and Valid_Next (Ctx, F_Source_Port) = Valid_Next (Ctx, F_Source_Port)'Old
       and Field_First (Ctx, F_Source_Port) = Field_First (Ctx, F_Source_Port)'Old;

   procedure Set_Destination_Port (Ctx : in out Context; Val : RFLX.UDP.Port) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Destination_Port)
       and then RFLX.UDP.Valid_Port (RFLX.UDP.To_Base_Integer (Val))
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Destination_Port) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Destination_Port)
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Destination_Port),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Destination_Port)
       and Get_Destination_Port (Ctx) = Val
       and Invalid (Ctx, F_Length)
       and Invalid (Ctx, F_Checksum)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Length) = F_Destination_Port
            and Valid_Next (Ctx, F_Length))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Destination_Port) = Predecessor (Ctx, F_Destination_Port)'Old
       and Valid_Next (Ctx, F_Destination_Port) = Valid_Next (Ctx, F_Destination_Port)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Field_First (Ctx, F_Destination_Port) = Field_First (Ctx, F_Destination_Port)'Old
       and (for all F in Field range F_Source_Port .. F_Source_Port =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_Length (Ctx : in out Context; Val : RFLX.UDP.Length) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Length)
       and then RFLX.UDP.Valid_Length (RFLX.UDP.To_Base_Integer (Val))
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Length) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Length)
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Length),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Length)
       and Get_Length (Ctx) = Val
       and Invalid (Ctx, F_Checksum)
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Checksum) = F_Length
            and Valid_Next (Ctx, F_Checksum))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Length) = Predecessor (Ctx, F_Length)'Old
       and Valid_Next (Ctx, F_Length) = Valid_Next (Ctx, F_Length)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and Field_First (Ctx, F_Length) = Field_First (Ctx, F_Length)'Old
       and (for all F in Field range F_Source_Port .. F_Destination_Port =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   procedure Set_Checksum (Ctx : in out Context; Val : RFLX.UDP.Checksum) with
     Inline_Always,
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Checksum)
       and then RFLX.UDP.Valid_Checksum (RFLX.UDP.To_Base_Integer (Val))
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Checksum) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Checksum)
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Checksum),
     Post =>
       Has_Buffer (Ctx)
       and Valid (Ctx, F_Checksum)
       and Get_Checksum (Ctx) = Val
       and Invalid (Ctx, F_Payload)
       and (Predecessor (Ctx, F_Payload) = F_Checksum
            and Valid_Next (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Checksum) = Predecessor (Ctx, F_Checksum)'Old
       and Valid_Next (Ctx, F_Checksum) = Valid_Next (Ctx, F_Checksum)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and Get_Length (Ctx) = Get_Length (Ctx)'Old
       and Field_First (Ctx, F_Checksum) = Field_First (Ctx, F_Checksum)'Old
       and (for all F in Field range F_Source_Port .. F_Length =>
               Context_Cursors_Index (Context_Cursors (Ctx), F) = Context_Cursors_Index (Context_Cursors (Ctx)'Old, F));

   pragma Warnings (On, "aspect ""*"" not enforced on inlined subprogram ""*""");

   procedure Set_Payload_Empty (Ctx : in out Context) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload) = 0,
     Post =>
       Has_Buffer (Ctx)
       and Well_Formed (Ctx, F_Payload)
       and (if Well_Formed_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and Get_Length (Ctx) = Get_Length (Ctx)'Old
       and Get_Checksum (Ctx) = Get_Checksum (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old;

   procedure Initialize_Payload (Ctx : in out Context) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload),
     Post =>
       Has_Buffer (Ctx)
       and then Well_Formed (Ctx, F_Payload)
       and then (if Well_Formed_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and then Ctx.Buffer_First = Ctx.Buffer_First'Old
       and then Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and then Ctx.First = Ctx.First'Old
       and then Ctx.Last = Ctx.Last'Old
       and then Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and then Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and then Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and then Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and then Get_Length (Ctx) = Get_Length (Ctx)'Old
       and then Get_Checksum (Ctx) = Get_Checksum (Ctx)'Old
       and then Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old;

   procedure Set_Payload (Ctx : in out Context; Data : RFLX_Types.Bytes) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Valid_Length (Ctx, RFLX.UDP.Datagram.F_Payload, Data'Length)
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload) >= Data'Length * RFLX_Types.Byte'Size
       and then RFLX.UDP.Datagram.Field_Condition (Ctx, RFLX.UDP.Datagram.F_Payload),
     Post =>
       Has_Buffer (Ctx)
       and Well_Formed (Ctx, F_Payload)
       and (if Well_Formed_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and Get_Length (Ctx) = Get_Length (Ctx)'Old
       and Get_Checksum (Ctx) = Get_Checksum (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old
       and Equal (Ctx, F_Payload, Data);

   generic
      with procedure Process_Payload (Payload : out RFLX_Types.Bytes);
      with function Process_Data_Pre (Length : RFLX_Types.Length) return Boolean;
   procedure Generic_Set_Payload (Ctx : in out Context; Length : RFLX_Types.Length) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Next (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload) >= RFLX.UDP.Datagram.Field_Size (Ctx, RFLX.UDP.Datagram.F_Payload)
       and then RFLX.UDP.Datagram.Valid_Length (Ctx, RFLX.UDP.Datagram.F_Payload, Length)
       and then RFLX_Types.To_Length (RFLX.UDP.Datagram.Available_Space (Ctx, RFLX.UDP.Datagram.F_Payload)) >= Length
       and then Process_Data_Pre (Length),
     Post =>
       Has_Buffer (Ctx)
       and Well_Formed (Ctx, F_Payload)
       and (if Well_Formed_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, F_Payload))
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Payload) = Predecessor (Ctx, F_Payload)'Old
       and Valid_Next (Ctx, F_Payload) = Valid_Next (Ctx, F_Payload)'Old
       and Get_Source_Port (Ctx) = Get_Source_Port (Ctx)'Old
       and Get_Destination_Port (Ctx) = Get_Destination_Port (Ctx)'Old
       and Get_Length (Ctx) = Get_Length (Ctx)'Old
       and Get_Checksum (Ctx) = Get_Checksum (Ctx)'Old
       and Field_First (Ctx, F_Payload) = Field_First (Ctx, F_Payload)'Old;

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

   type Structure is
      record
         Source_Port : RFLX.UDP.Port;
         Destination_Port : RFLX.UDP.Port;
         Length : RFLX.UDP.Length;
         Checksum : RFLX.UDP.Checksum;
         Payload : RFLX_Types.Bytes (RFLX_Types.Index'First .. RFLX_Types.Index'First + 65526);
      end record;

   function Valid_Structure (Unused_Struct : Structure) return Boolean;

   procedure To_Structure (Ctx : Context; Struct : out Structure) with
     Pre =>
       RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Well_Formed_Message (Ctx),
     Post =>
       Valid_Structure (Struct);

   function Sufficient_Buffer_Length (Ctx : Context; Struct : Structure) return Boolean;

   procedure To_Context (Struct : Structure; Ctx : in out Context) with
     Pre =>
       not Ctx'Constrained
       and then RFLX.UDP.Datagram.Has_Buffer (Ctx)
       and then RFLX.UDP.Datagram.Valid_Structure (Struct)
       and then RFLX.UDP.Datagram.Sufficient_Buffer_Length (Ctx, Struct),
     Post =>
       Has_Buffer (Ctx)
       and Well_Formed_Message (Ctx)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old;

   function Field_Size_Source_Port (Struct : Structure) return RFLX_Types.Bit_Length with
     Pre =>
       Valid_Structure (Struct);

   function Field_Size_Destination_Port (Struct : Structure) return RFLX_Types.Bit_Length with
     Pre =>
       Valid_Structure (Struct);

   function Field_Size_Length (Struct : Structure) return RFLX_Types.Bit_Length with
     Pre =>
       Valid_Structure (Struct);

   function Field_Size_Checksum (Struct : Structure) return RFLX_Types.Bit_Length with
     Pre =>
       Valid_Structure (Struct);

   function Field_Size_Payload (Struct : Structure) return RFLX_Types.Bit_Length with
     Pre =>
       Valid_Structure (Struct);

private

   type Cursor_State is (S_Valid, S_Well_Formed, S_Invalid, S_Incomplete);

   type Field_Cursor is
      record
         Predecessor : Virtual_Field := F_Final;
         State : Cursor_State := S_Invalid;
         First : RFLX_Types.Bit_Index := RFLX_Types.Bit_Index'First;
         Last : RFLX_Types.Bit_Length := RFLX_Types.Bit_Length'First;
         Value : RFLX_Types.Base_Integer := 0;
      end record;

   type Field_Cursors is array (Virtual_Field) of Field_Cursor;

   function Well_Formed (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Valid
      or Cursor.State = S_Well_Formed);

   function Valid (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Valid);

   function Invalid (Cursor : Field_Cursor) return Boolean is
     (Cursor.State = S_Invalid
      or Cursor.State = S_Incomplete);

   pragma Warnings (Off, "postcondition does not mention function result");

   function Cursors_Invariant (Cursors : Field_Cursors; First : RFLX_Types.Bit_Index; Verified_Last : RFLX_Types.Bit_Length) return Boolean is
     ((for all F in Field =>
          (if
              Well_Formed (Cursors (F))
           then
              Cursors (F).First >= First
              and Cursors (F).Last <= Verified_Last
              and Cursors (F).First <= Cursors (F).Last + 1
              and Valid_Value (F, Cursors (F).Value))))
    with
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   pragma Warnings (Off, "postcondition does not mention function result");

   pragma Warnings (Off, "unused variable ""*""");

   function Valid_Predecessors_Invariant (Cursors : Field_Cursors; First : RFLX_Types.Bit_Index; Verified_Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length; Buffer : RFLX_Types.Bytes_Ptr) return Boolean is
     ((if Well_Formed (Cursors (F_Source_Port)) then Cursors (F_Source_Port).Predecessor = F_Initial)
      and then (if
                   Well_Formed (Cursors (F_Destination_Port))
                then
                   (Valid (Cursors (F_Source_Port))
                    and then Cursors (F_Destination_Port).Predecessor = F_Source_Port))
      and then (if
                   Well_Formed (Cursors (F_Length))
                then
                   (Valid (Cursors (F_Destination_Port))
                    and then Cursors (F_Length).Predecessor = F_Destination_Port))
      and then (if
                   Well_Formed (Cursors (F_Checksum))
                then
                   (Valid (Cursors (F_Length))
                    and then Cursors (F_Checksum).Predecessor = F_Length))
      and then (if
                   Well_Formed (Cursors (F_Payload))
                then
                   (Valid (Cursors (F_Checksum))
                    and then Cursors (F_Payload).Predecessor = F_Checksum)))
    with
     Pre =>
       Cursors_Invariant (Cursors, First, Verified_Last),
     Post =>
       True;

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (On, "unused variable ""*""");

   pragma Warnings (Off, "postcondition does not mention function result");

   function Valid_Next_Internal (Cursors : Field_Cursors; First : RFLX_Types.Bit_Index; Verified_Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length; Buffer : RFLX_Types.Bytes_Ptr; Fld : Field) return Boolean is
     ((case Fld is
          when F_Source_Port =>
             Cursors (F_Source_Port).Predecessor = F_Initial,
          when F_Destination_Port =>
             (Valid (Cursors (F_Source_Port))
              and then True
              and then Cursors (F_Destination_Port).Predecessor = F_Source_Port),
          when F_Length =>
             (Valid (Cursors (F_Destination_Port))
              and then True
              and then Cursors (F_Length).Predecessor = F_Destination_Port),
          when F_Checksum =>
             (Valid (Cursors (F_Length))
              and then True
              and then Cursors (F_Checksum).Predecessor = F_Length),
          when F_Payload =>
             (Valid (Cursors (F_Checksum))
              and then True
              and then Cursors (F_Payload).Predecessor = F_Checksum)))
    with
     Pre =>
       Cursors_Invariant (Cursors, First, Verified_Last)
       and then Valid_Predecessors_Invariant (Cursors, First, Verified_Last, Written_Last, Buffer),
     Post =>
       True;

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (Off, "unused variable ""*""");

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   function Field_Size_Internal (Cursors : Field_Cursors; First : RFLX_Types.Bit_Index; Verified_Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length; Buffer : RFLX_Types.Bytes_Ptr; Fld : Field) return RFLX_Types.Bit_Length'Base is
     ((case Fld is
          when F_Source_Port | F_Destination_Port | F_Length | F_Checksum =>
             16,
          when F_Payload =>
             (RFLX_Types.Bit_Length (Cursors (F_Length).Value) - 8) * 8))
    with
     Pre =>
       Cursors_Invariant (Cursors, First, Verified_Last)
       and then Valid_Predecessors_Invariant (Cursors, First, Verified_Last, Written_Last, Buffer)
       and then Valid_Next_Internal (Cursors, First, Verified_Last, Written_Last, Buffer, Fld);

   pragma Warnings (On, "unused variable ""*""");

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

   pragma Warnings (Off, "postcondition does not mention function result");

   pragma Warnings (Off, "unused variable ""*""");

   pragma Warnings (Off, "no recursive call visible");

   pragma Warnings (Off, "formal parameter ""*"" is not referenced");

   function Field_First_Internal (Cursors : Field_Cursors; First : RFLX_Types.Bit_Index; Verified_Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length; Buffer : RFLX_Types.Bytes_Ptr; Fld : Field) return RFLX_Types.Bit_Index'Base is
     ((case Fld is
          when F_Source_Port =>
             First,
          when F_Destination_Port =>
             First + 16,
          when F_Length =>
             First + 32,
          when F_Checksum =>
             First + 48,
          when F_Payload =>
             First + 64))
    with
     Pre =>
       Cursors_Invariant (Cursors, First, Verified_Last)
       and then Valid_Predecessors_Invariant (Cursors, First, Verified_Last, Written_Last, Buffer)
       and then Valid_Next_Internal (Cursors, First, Verified_Last, Written_Last, Buffer, Fld),
     Post =>
       True,
     Subprogram_Variant =>
       (Decreases =>
         Fld);

   pragma Warnings (On, "postcondition does not mention function result");

   pragma Warnings (On, "unused variable ""*""");

   pragma Warnings (On, "no recursive call visible");

   pragma Warnings (On, "formal parameter ""*"" is not referenced");

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
      and then Cursors_Invariant (Cursors, First, Verified_Last)
      and then Valid_Predecessors_Invariant (Cursors, First, Verified_Last, Written_Last, Buffer)
      and then ((if Invalid (Cursors (F_Source_Port)) then Invalid (Cursors (F_Destination_Port)))
                and then (if Invalid (Cursors (F_Destination_Port)) then Invalid (Cursors (F_Length)))
                and then (if Invalid (Cursors (F_Length)) then Invalid (Cursors (F_Checksum)))
                and then (if Invalid (Cursors (F_Checksum)) then Invalid (Cursors (F_Payload))))
      and then ((if
                    Well_Formed (Cursors (F_Source_Port))
                 then
                    (Cursors (F_Source_Port).Last - Cursors (F_Source_Port).First + 1 = 16
                     and then Cursors (F_Source_Port).Predecessor = F_Initial
                     and then Cursors (F_Source_Port).First = First))
                and then (if
                             Well_Formed (Cursors (F_Destination_Port))
                          then
                             (Cursors (F_Destination_Port).Last - Cursors (F_Destination_Port).First + 1 = 16
                              and then Cursors (F_Destination_Port).Predecessor = F_Source_Port
                              and then Cursors (F_Destination_Port).First = Cursors (F_Source_Port).Last + 1))
                and then (if
                             Well_Formed (Cursors (F_Length))
                          then
                             (Cursors (F_Length).Last - Cursors (F_Length).First + 1 = 16
                              and then Cursors (F_Length).Predecessor = F_Destination_Port
                              and then Cursors (F_Length).First = Cursors (F_Destination_Port).Last + 1))
                and then (if
                             Well_Formed (Cursors (F_Checksum))
                          then
                             (Cursors (F_Checksum).Last - Cursors (F_Checksum).First + 1 = 16
                              and then Cursors (F_Checksum).Predecessor = F_Length
                              and then Cursors (F_Checksum).First = Cursors (F_Length).Last + 1))
                and then (if
                             Well_Formed (Cursors (F_Payload))
                          then
                             (Cursors (F_Payload).Last - Cursors (F_Payload).First + 1 = (RFLX_Types.Bit_Length (Cursors (F_Length).Value) - 8) * 8
                              and then Cursors (F_Payload).Predecessor = F_Checksum
                              and then Cursors (F_Payload).First = Cursors (F_Checksum).Last + 1))))
    with
     Post =>
       True;

   pragma Warnings (On, """Buffer"" is not modified, could be of access constant type");

   pragma Warnings (On, "postcondition does not mention function result");

   type Context (Buffer_First, Buffer_Last : RFLX_Types.Index := RFLX_Types.Index'First; First : RFLX_Types.Bit_Index := RFLX_Types.Bit_Index'First; Last : RFLX_Types.Bit_Length := RFLX_Types.Bit_Length'First) is
      record
         Verified_Last : RFLX_Types.Bit_Length := First - 1;
         Written_Last : RFLX_Types.Bit_Length := First - 1;
         Buffer : RFLX_Types.Bytes_Ptr := null;
         Cursors : Field_Cursors := (others => <>);
      end record with
     Dynamic_Predicate =>
       Valid_Context (Context.Buffer_First, Context.Buffer_Last, Context.First, Context.Last, Context.Verified_Last, Context.Written_Last, Context.Buffer, Context.Cursors);

   function Initialized (Ctx : Context) return Boolean is
     (Ctx.Verified_Last = Ctx.First - 1
      and then Valid_Next (Ctx, F_Source_Port)
      and then RFLX.UDP.Datagram.Field_First (Ctx, RFLX.UDP.Datagram.F_Source_Port) rem RFLX_Types.Byte'Size = 1
      and then Available_Space (Ctx, F_Source_Port) = Ctx.Last - Ctx.First + 1
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
          when F_Source_Port | F_Destination_Port =>
             RFLX.UDP.Valid_Port (Val),
          when F_Length =>
             RFLX.UDP.Valid_Length (Val),
          when F_Checksum =>
             RFLX.UDP.Valid_Checksum (Val),
          when F_Payload =>
             True));

   function Field_Condition (Ctx : Context; Fld : Field) return Boolean is
     ((case Fld is
          when F_Source_Port | F_Destination_Port | F_Length | F_Checksum | F_Payload =>
             True));

   function Field_Size (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     (Field_Size_Internal (Ctx.Cursors, Ctx.First, Ctx.Verified_Last, Ctx.Written_Last, Ctx.Buffer, Fld));

   function Field_First (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Index is
     (Field_First_Internal (Ctx.Cursors, Ctx.First, Ctx.Verified_Last, Ctx.Written_Last, Ctx.Buffer, Fld));

   function Field_Last (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     (Field_First (Ctx, Fld) + Field_Size (Ctx, Fld) - 1);

   function Predecessor (Ctx : Context; Fld : Virtual_Field) return Virtual_Field is
     ((case Fld is
          when F_Initial =>
             F_Initial,
          when others =>
             Ctx.Cursors (Fld).Predecessor));

   function Valid_Next (Ctx : Context; Fld : Field) return Boolean is
     (Valid_Next_Internal (Ctx.Cursors, Ctx.First, Ctx.Verified_Last, Ctx.Written_Last, Ctx.Buffer, Fld));

   function Available_Space (Ctx : Context; Fld : Field) return RFLX_Types.Bit_Length is
     (Ctx.Last - Field_First (Ctx, Fld) + 1);

   function Sufficient_Space (Ctx : Context; Fld : Field) return Boolean is
     (Available_Space (Ctx, Fld) >= Field_Size (Ctx, Fld));

   function Present (Ctx : Context; Fld : Field) return Boolean is
     (Well_Formed (Ctx.Cursors (Fld))
      and then Ctx.Cursors (Fld).First < Ctx.Cursors (Fld).Last + 1);

   function Well_Formed (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Valid
      or Ctx.Cursors (Fld).State = S_Well_Formed);

   function Valid (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Valid
      and then Ctx.Cursors (Fld).First < Ctx.Cursors (Fld).Last + 1);

   function Incomplete (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Incomplete);

   function Invalid (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Cursors (Fld).State = S_Invalid
      or Ctx.Cursors (Fld).State = S_Incomplete);

   function Well_Formed_Message (Ctx : Context) return Boolean is
     (Well_Formed (Ctx, F_Payload));

   function Valid_Message (Ctx : Context) return Boolean is
     (Valid (Ctx, F_Payload));

   function Incomplete_Message (Ctx : Context) return Boolean is
     ((for some F in Field =>
          Incomplete (Ctx, F)));

   function Get_Source_Port (Ctx : Context) return RFLX.UDP.Port is
     (To_Actual (Ctx.Cursors (F_Source_Port).Value));

   function Get_Destination_Port (Ctx : Context) return RFLX.UDP.Port is
     (To_Actual (Ctx.Cursors (F_Destination_Port).Value));

   function Get_Length (Ctx : Context) return RFLX.UDP.Length is
     (To_Actual (Ctx.Cursors (F_Length).Value));

   function Get_Checksum (Ctx : Context) return RFLX.UDP.Checksum is
     (To_Actual (Ctx.Cursors (F_Checksum).Value));

   function Valid_Size (Ctx : Context; Fld : Field; Size : RFLX_Types.Bit_Length) return Boolean is
     (Size = Field_Size (Ctx, Fld))
    with
     Pre =>
       RFLX.UDP.Datagram.Valid_Next (Ctx, Fld);

   function Valid_Length (Ctx : Context; Fld : Field; Length : RFLX_Types.Length) return Boolean is
     (Valid_Size (Ctx, Fld, RFLX_Types.To_Bit_Length (Length)));

   function Context_Cursor (Ctx : Context; Fld : Field) return Field_Cursor is
     (Ctx.Cursors (Fld));

   function Context_Cursors (Ctx : Context) return Field_Cursors is
     (Ctx.Cursors);

   function Context_Cursors_Index (Cursors : Field_Cursors; Fld : Field) return Field_Cursor is
     (Cursors (Fld));

   function Valid_Structure (Unused_Struct : Structure) return Boolean is
     (True);

   function Sufficient_Buffer_Length (Ctx : Context; Struct : Structure) return Boolean is
     (RFLX_Types.Base_Integer (RFLX_Types.To_Last_Bit_Index (Ctx.Buffer_Last) - RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First) + 1) >= (RFLX_Types.Base_Integer (Struct.Length) - 8) * 8 + 64);

   function Field_Size_Source_Port (Struct : Structure) return RFLX_Types.Bit_Length is
     (16);

   function Field_Size_Destination_Port (Struct : Structure) return RFLX_Types.Bit_Length is
     (16);

   function Field_Size_Length (Struct : Structure) return RFLX_Types.Bit_Length is
     (16);

   function Field_Size_Checksum (Struct : Structure) return RFLX_Types.Bit_Length is
     (16);

   function Field_Size_Payload (Struct : Structure) return RFLX_Types.Bit_Length is
     ((RFLX_Types.Bit_Length (Struct.Length) - 8) * 8);

end RFLX.UDP.Datagram;
