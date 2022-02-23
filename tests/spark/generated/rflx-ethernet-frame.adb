pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");

package body RFLX.Ethernet.Frame with
  SPARK_Mode
is

   procedure Initialize (Ctx : out Context; Buffer : in out RFLX_Types.Bytes_Ptr; Written_Last : RFLX_Types.Bit_Length := 0) is
   begin
      Initialize (Ctx, Buffer, RFLX_Types.To_First_Bit_Index (Buffer'First), RFLX_Types.To_Last_Bit_Index (Buffer'Last), Written_Last);
   end Initialize;

   procedure Initialize (Ctx : out Context; Buffer : in out RFLX_Types.Bytes_Ptr; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length; Written_Last : RFLX_Types.Bit_Length := 0) is
      Buffer_First : constant RFLX_Types.Index := Buffer'First;
      Buffer_Last : constant RFLX_Types.Index := Buffer'Last;
   begin
      Ctx := (Buffer_First, Buffer_Last, First, Last, First - 1, (if Written_Last = 0 then First - 1 else Written_Last), Buffer, (F_Destination => (State => S_Invalid, Predecessor => F_Initial), others => (State => S_Invalid, Predecessor => F_Final)));
      Buffer := null;
   end Initialize;

   procedure Reset (Ctx : in out Context) is
   begin
      Reset (Ctx, RFLX_Types.To_First_Bit_Index (Ctx.Buffer'First), RFLX_Types.To_Last_Bit_Index (Ctx.Buffer'Last));
   end Reset;

   procedure Reset (Ctx : in out Context; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length) is
   begin
      Ctx := (Ctx.Buffer_First, Ctx.Buffer_Last, First, Last, First - 1, First - 1, Ctx.Buffer, (F_Destination => (State => S_Invalid, Predecessor => F_Initial), others => (State => S_Invalid, Predecessor => F_Final)));
   end Reset;

   procedure Take_Buffer (Ctx : in out Context; Buffer : out RFLX_Types.Bytes_Ptr) is
   begin
      Buffer := Ctx.Buffer;
      Ctx.Buffer := null;
   end Take_Buffer;

   procedure Copy (Ctx : Context; Buffer : out RFLX_Types.Bytes) is
   begin
      if Buffer'Length > 0 then
         Buffer := Ctx.Buffer.all (RFLX_Types.To_Index (Ctx.First) .. RFLX_Types.To_Index (Ctx.Verified_Last));
      else
         Buffer := Ctx.Buffer.all (1 .. 0);
      end if;
   end Copy;

   function Read (Ctx : Context) return RFLX_Types.Bytes is
     (Ctx.Buffer.all (RFLX_Types.To_Index (Ctx.First) .. RFLX_Types.To_Index (Ctx.Verified_Last)));

   procedure Generic_Read (Ctx : Context) is
   begin
      Read (Ctx.Buffer.all (RFLX_Types.To_Index (Ctx.First) .. RFLX_Types.To_Index (Ctx.Verified_Last)));
   end Generic_Read;

   procedure Generic_Write (Ctx : in out Context; Offset : RFLX_Types.Length := 0) is
      Length : RFLX_Types.Length;
   begin
      Reset (Ctx, RFLX_Types.To_First_Bit_Index (Ctx.Buffer_First), RFLX_Types.To_Last_Bit_Index (Ctx.Buffer_Last));
      Write (Ctx.Buffer.all (Ctx.Buffer'First + RFLX_Types.Index (Offset + 1) - 1 .. Ctx.Buffer'Last), Length, Ctx.Buffer'Length, Offset);
      pragma Assert (Length <= Ctx.Buffer.all'Length, "Length <= Buffer'Length is not ensured by postcondition of ""Write""");
      Ctx.Written_Last := RFLX_Types.Bit_Index'Max (Ctx.Written_Last, RFLX_Types.To_Last_Bit_Index (RFLX_Types.Length (Ctx.Buffer_First) + Offset + Length - 1));
   end Generic_Write;

   function Size (Ctx : Context) return RFLX_Types.Bit_Length is
     ((if Ctx.Verified_Last = Ctx.First - 1 then 0 else Ctx.Verified_Last - Ctx.First + 1));

   function Byte_Size (Ctx : Context) return RFLX_Types.Length is
     ((if
          Ctx.Verified_Last = Ctx.First - 1
       then
          0
       else
          RFLX_Types.Length (RFLX_Types.To_Index (Ctx.Verified_Last) - RFLX_Types.To_Index (Ctx.First) + 1)));

   procedure Message_Data (Ctx : Context; Data : out RFLX_Types.Bytes) is
   begin
      Data := Ctx.Buffer.all (RFLX_Types.To_Index (Ctx.First) .. RFLX_Types.To_Index (Ctx.Verified_Last));
   end Message_Data;

   pragma Warnings (Off, "precondition is always False");

   function Successor (Ctx : Context; Fld : Field) return Virtual_Field is
     ((case Fld is
          when F_Destination =>
             F_Source,
          when F_Source =>
             F_Type_Length_TPID,
          when F_Type_Length_TPID =>
             (if
                 Ctx.Cursors (F_Type_Length_TPID).Value.Type_Length_TPID_Value = 16#8100#
              then
                 F_TPID
              elsif
                 Ctx.Cursors (F_Type_Length_TPID).Value.Type_Length_TPID_Value /= 16#8100#
              then
                 F_Type_Length
              else
                 F_Initial),
          when F_TPID =>
             F_TCI,
          when F_TCI =>
             F_Type_Length,
          when F_Type_Length =>
             (if
                 Ctx.Cursors (F_Type_Length).Value.Type_Length_Value <= 1500
              then
                 F_Payload
              elsif
                 Ctx.Cursors (F_Type_Length).Value.Type_Length_Value >= 1536
              then
                 F_Payload
              else
                 F_Initial),
          when F_Payload =>
             (if
                 RFLX_Types.U64 (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 >= 46
                 and RFLX_Types.U64 (Ctx.Cursors (F_Payload).Last - Ctx.Cursors (F_Payload).First + 1) / 8 <= 1500
              then
                 F_Final
              else
                 F_Initial)))
    with
     Pre =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, Fld)
       and Valid_Predecessor (Ctx, Fld);

   pragma Warnings (On, "precondition is always False");

   function Invalid_Successor (Ctx : Context; Fld : Field) return Boolean is
     ((case Fld is
          when F_Destination =>
             Invalid (Ctx.Cursors (F_Source)),
          when F_Source =>
             Invalid (Ctx.Cursors (F_Type_Length_TPID)),
          when F_Type_Length_TPID =>
             Invalid (Ctx.Cursors (F_TPID))
             and Invalid (Ctx.Cursors (F_Type_Length)),
          when F_TPID =>
             Invalid (Ctx.Cursors (F_TCI)),
          when F_TCI =>
             Invalid (Ctx.Cursors (F_Type_Length)),
          when F_Type_Length =>
             Invalid (Ctx.Cursors (F_Payload)),
          when F_Payload =>
             True));

   function Sufficient_Buffer_Length (Ctx : Context; Fld : Field) return Boolean is
     (Ctx.Buffer /= null
      and Field_First (Ctx, Fld) + Field_Size (Ctx, Fld) < RFLX_Types.Bit_Length'Last
      and Ctx.First <= Field_First (Ctx, Fld)
      and Field_First (Ctx, Fld) + Field_Size (Ctx, Fld) - 1 <= Ctx.Written_Last)
    with
     Pre =>
       Has_Buffer (Ctx)
       and Valid_Next (Ctx, Fld);

   function Equal (Ctx : Context; Fld : Field; Data : RFLX_Types.Bytes) return Boolean is
     (Sufficient_Buffer_Length (Ctx, Fld)
      and then (case Fld is
                   when F_Payload =>
                      Ctx.Buffer.all (RFLX_Types.To_Index (Field_First (Ctx, Fld)) .. RFLX_Types.To_Index (Field_Last (Ctx, Fld))) = Data,
                   when others =>
                      False));

   procedure Reset_Dependent_Fields (Ctx : in out Context; Fld : Field) with
     Pre =>
       Valid_Next (Ctx, Fld),
     Post =>
       Valid_Next (Ctx, Fld)
       and Invalid (Ctx.Cursors (Fld))
       and Invalid_Successor (Ctx, Fld)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Ctx.Cursors (Fld).Predecessor = Ctx.Cursors (Fld).Predecessor'Old
       and Has_Buffer (Ctx) = Has_Buffer (Ctx)'Old
       and Field_First (Ctx, Fld) = Field_First (Ctx, Fld)'Old
       and Field_Size (Ctx, Fld) = Field_Size (Ctx, Fld)'Old
       and (for all F in Field =>
               (if F < Fld then Ctx.Cursors (F) = Ctx.Cursors'Old (F) else Invalid (Ctx, F)))
   is
      First : constant RFLX_Types.Bit_Length := Field_First (Ctx, Fld) with
        Ghost;
      Size : constant RFLX_Types.Bit_Length := Field_Size (Ctx, Fld) with
        Ghost;
   begin
      pragma Assert (Field_First (Ctx, Fld) = First
                     and Field_Size (Ctx, Fld) = Size);
      for Fld_Loop in reverse Field'Succ (Fld) .. Field'Last loop
         Ctx.Cursors (Fld_Loop) := (S_Invalid, F_Final);
         pragma Loop_Invariant (Field_First (Ctx, Fld) = First
                                and Field_Size (Ctx, Fld) = Size);
         pragma Loop_Invariant ((for all F in Field =>
                                    (if F < Fld_Loop then Ctx.Cursors (F) = Ctx.Cursors'Loop_Entry (F) else Invalid (Ctx, F))));
      end loop;
      pragma Assert (Field_First (Ctx, Fld) = First
                     and Field_Size (Ctx, Fld) = Size);
      Ctx.Cursors (Fld) := (S_Invalid, Ctx.Cursors (Fld).Predecessor);
      pragma Assert (Field_First (Ctx, Fld) = First
                     and Field_Size (Ctx, Fld) = Size);
   end Reset_Dependent_Fields;

   function Composite_Field (Fld : Field) return Boolean is
     (Fld in F_Payload);

   function Get_Field_Value (Ctx : Context; Fld : Field) return Field_Dependent_Value with
     Pre =>
       Has_Buffer (Ctx)
       and then Valid_Next (Ctx, Fld)
       and then Sufficient_Buffer_Length (Ctx, Fld),
     Post =>
       Get_Field_Value'Result.Fld = Fld
   is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, Fld);
      Last : constant RFLX_Types.Bit_Index := Field_Last (Ctx, Fld);
      Buffer_First : constant RFLX_Types.Index := RFLX_Types.To_Index (First);
      Buffer_Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Last);
      Offset : constant RFLX_Types.Offset := RFLX_Types.Offset ((RFLX_Types.Byte'Size - Last mod RFLX_Types.Byte'Size) mod RFLX_Types.Byte'Size);
      function Extract is new RFLX_Types.Extract (RFLX.Ethernet.Address);
      function Extract is new RFLX_Types.Extract (RFLX.Ethernet.Type_Length_Base);
      function Extract is new RFLX_Types.Extract (RFLX.Ethernet.TPID_Base);
      function Extract is new RFLX_Types.Extract (RFLX.Ethernet.TCI);
   begin
      return ((case Fld is
                  when F_Destination =>
                     (Fld => F_Destination, Destination_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Source =>
                     (Fld => F_Source, Source_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Type_Length_TPID =>
                     (Fld => F_Type_Length_TPID, Type_Length_TPID_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_TPID =>
                     (Fld => F_TPID, TPID_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_TCI =>
                     (Fld => F_TCI, TCI_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Type_Length =>
                     (Fld => F_Type_Length, Type_Length_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Payload =>
                     (Fld => F_Payload)));
   end Get_Field_Value;

   procedure Verify (Ctx : in out Context; Fld : Field) is
      Value : Field_Dependent_Value;
   begin
      if
         Has_Buffer (Ctx)
         and then Invalid (Ctx.Cursors (Fld))
         and then Valid_Predecessor (Ctx, Fld)
         and then Path_Condition (Ctx, Fld)
      then
         if Sufficient_Buffer_Length (Ctx, Fld) then
            Value := Get_Field_Value (Ctx, Fld);
            if
               Valid_Value (Value)
               and Field_Condition (Ctx, Value, Field_Size (Ctx, Fld))
            then
               pragma Assert ((if Fld = F_Payload then Field_Last (Ctx, Fld) mod RFLX_Types.Byte'Size = 0));
               pragma Assert ((((Field_Last (Ctx, Fld) + RFLX_Types.Byte'Size - 1) / RFLX_Types.Byte'Size) * RFLX_Types.Byte'Size) mod RFLX_Types.Byte'Size = 0);
               Ctx.Verified_Last := ((Field_Last (Ctx, Fld) + RFLX_Types.Byte'Size - 1) / RFLX_Types.Byte'Size) * RFLX_Types.Byte'Size;
               pragma Assert (Field_Last (Ctx, Fld) <= Ctx.Verified_Last);
               if Composite_Field (Fld) then
                  Ctx.Cursors (Fld) := (State => S_Structural_Valid, First => Field_First (Ctx, Fld), Last => Field_Last (Ctx, Fld), Value => Value, Predecessor => Ctx.Cursors (Fld).Predecessor);
               else
                  Ctx.Cursors (Fld) := (State => S_Valid, First => Field_First (Ctx, Fld), Last => Field_Last (Ctx, Fld), Value => Value, Predecessor => Ctx.Cursors (Fld).Predecessor);
               end if;
               for F in Field loop
                  if Fld = F then
                     Ctx.Cursors (Successor (Ctx, Fld)) := (State => S_Invalid, Predecessor => Fld);
                  end if;
               end loop;
            else
               Ctx.Cursors (Fld) := (State => S_Invalid, Predecessor => F_Final);
            end if;
         else
            Ctx.Cursors (Fld) := (State => S_Incomplete, Predecessor => F_Final);
         end if;
      end if;
   end Verify;

   procedure Verify_Message (Ctx : in out Context) is
   begin
      for F in Field loop
         Verify (Ctx, F);
      end loop;
   end Verify_Message;

   function Get_Payload (Ctx : Context) return RFLX_Types.Bytes is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).Last);
   begin
      return Ctx.Buffer.all (First .. Last);
   end Get_Payload;

   procedure Get_Payload (Ctx : Context; Data : out RFLX_Types.Bytes) is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).Last);
   begin
      Data := (others => RFLX_Types.Byte'First);
      Data (Data'First .. Data'First + (Last - First)) := Ctx.Buffer.all (First .. Last);
   end Get_Payload;

   procedure Generic_Get_Payload (Ctx : Context) is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Payload).Last);
   begin
      Process_Payload (Ctx.Buffer.all (First .. Last));
   end Generic_Get_Payload;

   procedure Set (Ctx : in out Context; Val : Field_Dependent_Value; Size : RFLX_Types.Bit_Length; State_Valid : Boolean; Buffer_First : out RFLX_Types.Index; Buffer_Last : out RFLX_Types.Index; Offset : out RFLX_Types.Offset) with
     Pre =>
       Has_Buffer (Ctx)
       and then Val.Fld in Field
       and then Valid_Next (Ctx, Val.Fld)
       and then Valid_Value (Val)
       and then Valid_Size (Ctx, Val.Fld, Size)
       and then Size <= Available_Space (Ctx, Val.Fld)
       and then (if Composite_Field (Val.Fld) then Size mod RFLX_Types.Byte'Size = 0 else State_Valid),
     Post =>
       Valid_Next (Ctx, Val.Fld)
       and Invalid_Successor (Ctx, Val.Fld)
       and Buffer_First = RFLX_Types.To_Index (Field_First (Ctx, Val.Fld))
       and Buffer_Last = RFLX_Types.To_Index (Field_First (Ctx, Val.Fld) + Size - 1)
       and Offset = RFLX_Types.Offset ((RFLX_Types.Byte'Size - (Field_First (Ctx, Val.Fld) + Size - 1) mod RFLX_Types.Byte'Size) mod RFLX_Types.Byte'Size)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Has_Buffer (Ctx) = Has_Buffer (Ctx)'Old
       and Predecessor (Ctx, Val.Fld) = Predecessor (Ctx, Val.Fld)'Old
       and Field_First (Ctx, Val.Fld) = Field_First (Ctx, Val.Fld)'Old
       and (if State_Valid and Size > 0 then Valid (Ctx, Val.Fld) else Structural_Valid (Ctx, Val.Fld))
       and (case Val.Fld is
               when F_Initial =>
                  (Predecessor (Ctx, F_Destination) = F_Initial
                   and Valid_Next (Ctx, F_Destination)),
               when F_Destination =>
                  Get_Destination (Ctx) = To_Actual (Val.Destination_Value)
                  and (Predecessor (Ctx, F_Source) = F_Destination
                       and Valid_Next (Ctx, F_Source)),
               when F_Source =>
                  Get_Source (Ctx) = To_Actual (Val.Source_Value)
                  and (Predecessor (Ctx, F_Type_Length_TPID) = F_Source
                       and Valid_Next (Ctx, F_Type_Length_TPID)),
               when F_Type_Length_TPID =>
                  Get_Type_Length_TPID (Ctx) = To_Actual (Val.Type_Length_TPID_Value)
                  and (if
                          Get_Type_Length_TPID (Ctx) = 16#8100#
                       then
                          Predecessor (Ctx, F_TPID) = F_Type_Length_TPID
                          and Valid_Next (Ctx, F_TPID))
                  and (if
                          Get_Type_Length_TPID (Ctx) /= 16#8100#
                       then
                          Predecessor (Ctx, F_Type_Length) = F_Type_Length_TPID
                          and Valid_Next (Ctx, F_Type_Length)),
               when F_TPID =>
                  (Predecessor (Ctx, F_TCI) = F_TPID
                   and Valid_Next (Ctx, F_TCI)),
               when F_TCI =>
                  Get_TCI (Ctx) = To_Actual (Val.TCI_Value)
                  and (Predecessor (Ctx, F_Type_Length) = F_TCI
                       and Valid_Next (Ctx, F_Type_Length)),
               when F_Type_Length =>
                  Get_Type_Length (Ctx) = To_Actual (Val.Type_Length_Value)
                  and (if
                          Get_Type_Length (Ctx) <= 1500
                       then
                          Predecessor (Ctx, F_Payload) = F_Type_Length
                          and Valid_Next (Ctx, F_Payload))
                  and (if
                          Get_Type_Length (Ctx) >= 1536
                       then
                          Predecessor (Ctx, F_Payload) = F_Type_Length
                          and Valid_Next (Ctx, F_Payload)),
               when F_Payload =>
                  (if Structural_Valid_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, Val.Fld)),
               when F_Final =>
                  True)
       and (for all F in Field =>
               (if F < Val.Fld then Ctx.Cursors (F) = Ctx.Cursors'Old (F)))
   is
      First : RFLX_Types.Bit_Index;
      Last : RFLX_Types.Bit_Length;
   begin
      Reset_Dependent_Fields (Ctx, Val.Fld);
      First := Field_First (Ctx, Val.Fld);
      Last := Field_First (Ctx, Val.Fld) + Size - 1;
      Offset := RFLX_Types.Offset ((RFLX_Types.Byte'Size - Last mod RFLX_Types.Byte'Size) mod RFLX_Types.Byte'Size);
      Buffer_First := RFLX_Types.To_Index (First);
      Buffer_Last := RFLX_Types.To_Index (Last);
      pragma Assert ((((Last + RFLX_Types.Byte'Size - 1) / RFLX_Types.Byte'Size) * RFLX_Types.Byte'Size) mod RFLX_Types.Byte'Size = 0);
      pragma Warnings (Off, "attribute Update is an obsolescent feature");
      Ctx := Ctx'Update (Verified_Last => ((Last + RFLX_Types.Byte'Size - 1) / RFLX_Types.Byte'Size) * RFLX_Types.Byte'Size, Written_Last => ((Last + RFLX_Types.Byte'Size - 1) / RFLX_Types.Byte'Size) * RFLX_Types.Byte'Size);
      pragma Warnings (On, "attribute Update is an obsolescent feature");
      if State_Valid then
         Ctx.Cursors (Val.Fld) := (State => S_Valid, First => First, Last => Last, Value => Val, Predecessor => Ctx.Cursors (Val.Fld).Predecessor);
      else
         Ctx.Cursors (Val.Fld) := (State => S_Structural_Valid, First => First, Last => Last, Value => Val, Predecessor => Ctx.Cursors (Val.Fld).Predecessor);
      end if;
      Ctx.Cursors (Successor (Ctx, Val.Fld)) := (State => S_Invalid, Predecessor => Val.Fld);
   end Set;

   procedure Set_Destination (Ctx : in out Context; Val : RFLX.Ethernet.Address) is
      Field_Value : constant Field_Dependent_Value := (F_Destination, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.Address);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Destination), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Destination_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Destination;

   procedure Set_Source (Ctx : in out Context; Val : RFLX.Ethernet.Address) is
      Field_Value : constant Field_Dependent_Value := (F_Source, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.Address);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Source), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Source_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Source;

   procedure Set_Type_Length_TPID (Ctx : in out Context; Val : RFLX.Ethernet.Type_Length) is
      Field_Value : constant Field_Dependent_Value := (F_Type_Length_TPID, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.Type_Length_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Type_Length_TPID), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Type_Length_TPID_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Type_Length_TPID;

   procedure Set_TPID (Ctx : in out Context; Val : RFLX.Ethernet.TPID) is
      Field_Value : constant Field_Dependent_Value := (F_TPID, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.TPID_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_TPID), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.TPID_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_TPID;

   procedure Set_TCI (Ctx : in out Context; Val : RFLX.Ethernet.TCI) is
      Field_Value : constant Field_Dependent_Value := (F_TCI, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.TCI);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_TCI), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.TCI_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_TCI;

   procedure Set_Type_Length (Ctx : in out Context; Val : RFLX.Ethernet.Type_Length) is
      Field_Value : constant Field_Dependent_Value := (F_Type_Length, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.Ethernet.Type_Length_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Type_Length), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Type_Length_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Type_Length;

   procedure Initialize_Payload_Private (Ctx : in out Context; Length : RFLX_Types.Length) with
     Pre =>
       not Ctx'Constrained
       and then Has_Buffer (Ctx)
       and then Valid_Next (Ctx, F_Payload)
       and then Valid_Length (Ctx, F_Payload, Length)
       and then RFLX_Types.To_Length (Available_Space (Ctx, F_Payload)) >= Length
       and then Field_First (Ctx, F_Payload) mod RFLX_Types.Byte'Size = 1,
     Post =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, F_Payload)
       and Field_Size (Ctx, F_Payload) = RFLX_Types.To_Bit_Length (Length)
       and Ctx.Verified_Last = Field_Last (Ctx, F_Payload)
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
   is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Payload);
      Last : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Payload) + RFLX_Types.Bit_Length (Length) * RFLX_Types.Byte'Size - 1;
   begin
      pragma Assert (Last mod RFLX_Types.Byte'Size = 0);
      Reset_Dependent_Fields (Ctx, F_Payload);
      pragma Warnings (Off, "attribute Update is an obsolescent feature");
      Ctx := Ctx'Update (Verified_Last => Last, Written_Last => Last);
      pragma Warnings (On, "attribute Update is an obsolescent feature");
      Ctx.Cursors (F_Payload) := (State => S_Structural_Valid, First => First, Last => Last, Value => (Fld => F_Payload), Predecessor => Ctx.Cursors (F_Payload).Predecessor);
      Ctx.Cursors (Successor (Ctx, F_Payload)) := (State => S_Invalid, Predecessor => F_Payload);
   end Initialize_Payload_Private;

   procedure Initialize_Payload (Ctx : in out Context; Length : RFLX_Types.Length) is
   begin
      Initialize_Payload_Private (Ctx, Length);
   end Initialize_Payload;

   procedure Set_Payload (Ctx : in out Context; Data : RFLX_Types.Bytes) is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Payload);
      Buffer_First : constant RFLX_Types.Index := RFLX_Types.To_Index (First);
      Buffer_Last : constant RFLX_Types.Index := Buffer_First + Data'Length - 1;
   begin
      Initialize_Payload_Private (Ctx, Data'Length);
      Ctx.Buffer.all (Buffer_First .. Buffer_Last) := Data;
   end Set_Payload;

   procedure Generic_Set_Payload (Ctx : in out Context; Length : RFLX_Types.Length) is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Payload);
      Buffer_First : constant RFLX_Types.Index := RFLX_Types.To_Index (First);
      Buffer_Last : constant RFLX_Types.Index := RFLX_Types.To_Index (First + RFLX_Types.To_Bit_Length (Length) - 1);
   begin
      Process_Payload (Ctx.Buffer.all (Buffer_First .. Buffer_Last));
      Initialize_Payload_Private (Ctx, Length);
   end Generic_Set_Payload;

end RFLX.Ethernet.Frame;
