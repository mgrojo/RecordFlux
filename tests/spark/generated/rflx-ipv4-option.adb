pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");

package body RFLX.IPv4.Option with
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
      Ctx := (Buffer_First, Buffer_Last, First, Last, First - 1, (if Written_Last = 0 then First - 1 else Written_Last), Buffer, (F_Copied => (State => S_Invalid, Predecessor => F_Initial), others => (State => S_Invalid, Predecessor => F_Final)));
      Buffer := null;
   end Initialize;

   procedure Reset (Ctx : in out Context) is
   begin
      Reset (Ctx, RFLX_Types.To_First_Bit_Index (Ctx.Buffer'First), RFLX_Types.To_Last_Bit_Index (Ctx.Buffer'Last));
   end Reset;

   procedure Reset (Ctx : in out Context; First : RFLX_Types.Bit_Index; Last : RFLX_Types.Bit_Length) is
   begin
      Ctx := (Ctx.Buffer_First, Ctx.Buffer_Last, First, Last, First - 1, First - 1, Ctx.Buffer, (F_Copied => (State => S_Invalid, Predecessor => F_Initial), others => (State => S_Invalid, Predecessor => F_Final)));
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
          when F_Copied =>
             F_Option_Class,
          when F_Option_Class =>
             F_Option_Number,
          when F_Option_Number =>
             (if
                 RFLX_Types.U64 (Ctx.Cursors (F_Option_Class).Value.Option_Class_Value) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                 and Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 1
              then
                 F_Final
              elsif
                 Ctx.Cursors (F_Option_Number).Value.Option_Number_Value > 1
              then
                 F_Option_Length
              else
                 F_Initial),
          when F_Option_Length =>
             (if
                 (RFLX_Types.U64 (Ctx.Cursors (F_Option_Class).Value.Option_Class_Value) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Debugging_And_Measurement))
                  and Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 4)
                 or (RFLX_Types.U64 (Ctx.Cursors (F_Option_Class).Value.Option_Class_Value) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                     and (Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 9
                          or Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 3
                          or Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 7))
                 or (Ctx.Cursors (F_Option_Length).Value.Option_Length_Value = 11
                     and RFLX_Types.U64 (Ctx.Cursors (F_Option_Class).Value.Option_Class_Value) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                     and Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 2)
                 or (Ctx.Cursors (F_Option_Length).Value.Option_Length_Value = 4
                     and RFLX_Types.U64 (Ctx.Cursors (F_Option_Class).Value.Option_Class_Value) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                     and Ctx.Cursors (F_Option_Number).Value.Option_Number_Value = 8)
              then
                 F_Option_Data
              else
                 F_Initial),
          when F_Option_Data =>
             F_Final))
    with
     Pre =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, Fld)
       and Valid_Predecessor (Ctx, Fld);

   pragma Warnings (On, "precondition is always False");

   function Invalid_Successor (Ctx : Context; Fld : Field) return Boolean is
     ((case Fld is
          when F_Copied =>
             Invalid (Ctx.Cursors (F_Option_Class)),
          when F_Option_Class =>
             Invalid (Ctx.Cursors (F_Option_Number)),
          when F_Option_Number =>
             Invalid (Ctx.Cursors (F_Option_Length)),
          when F_Option_Length =>
             Invalid (Ctx.Cursors (F_Option_Data)),
          when F_Option_Data =>
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
                   when F_Option_Data =>
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
     (Fld in F_Option_Data);

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
      function Extract is new RFLX_Types.Extract (RFLX.RFLX_Builtin_Types.Boolean_Base);
      function Extract is new RFLX_Types.Extract (RFLX.IPv4.Option_Class_Base);
      function Extract is new RFLX_Types.Extract (RFLX.IPv4.Option_Number);
      function Extract is new RFLX_Types.Extract (RFLX.IPv4.Option_Length_Base);
   begin
      return ((case Fld is
                  when F_Copied =>
                     (Fld => F_Copied, Copied_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Option_Class =>
                     (Fld => F_Option_Class, Option_Class_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Option_Number =>
                     (Fld => F_Option_Number, Option_Number_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Option_Length =>
                     (Fld => F_Option_Length, Option_Length_Value => Extract (Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First)),
                  when F_Option_Data =>
                     (Fld => F_Option_Data)));
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
               and Field_Condition (Ctx, Value)
            then
               pragma Assert ((if
                                  Fld = F_Option_Data
                                  or Fld = F_Option_Number
                               then
                                  Field_Last (Ctx, Fld) mod RFLX_Types.Byte'Size = 0));
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

   function Get_Option_Data (Ctx : Context) return RFLX_Types.Bytes is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).Last);
   begin
      return Ctx.Buffer.all (First .. Last);
   end Get_Option_Data;

   procedure Get_Option_Data (Ctx : Context; Data : out RFLX_Types.Bytes) is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).Last);
   begin
      Data := (others => RFLX_Types.Byte'First);
      Data (Data'First .. Data'First + (Last - First)) := Ctx.Buffer.all (First .. Last);
   end Get_Option_Data;

   procedure Generic_Get_Option_Data (Ctx : Context) is
      First : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).First);
      Last : constant RFLX_Types.Index := RFLX_Types.To_Index (Ctx.Cursors (F_Option_Data).Last);
   begin
      Process_Option_Data (Ctx.Buffer.all (First .. Last));
   end Generic_Get_Option_Data;

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
                  (Predecessor (Ctx, F_Copied) = F_Initial
                   and Valid_Next (Ctx, F_Copied)),
               when F_Copied =>
                  Get_Copied (Ctx) = To_Actual (Val.Copied_Value)
                  and (Predecessor (Ctx, F_Option_Class) = F_Copied
                       and Valid_Next (Ctx, F_Option_Class)),
               when F_Option_Class =>
                  Get_Option_Class (Ctx) = To_Actual (Val.Option_Class_Value)
                  and (Predecessor (Ctx, F_Option_Number) = F_Option_Class
                       and Valid_Next (Ctx, F_Option_Number)),
               when F_Option_Number =>
                  Get_Option_Number (Ctx) = To_Actual (Val.Option_Number_Value)
                  and (if
                          Get_Option_Number (Ctx) > 1
                       then
                          Predecessor (Ctx, F_Option_Length) = F_Option_Number
                          and Valid_Next (Ctx, F_Option_Length))
                  and (if Structural_Valid_Message (Ctx) then Message_Last (Ctx) = Field_Last (Ctx, Val.Fld)),
               when F_Option_Length =>
                  Get_Option_Length (Ctx) = To_Actual (Val.Option_Length_Value)
                  and (if
                          (RFLX_Types.U64 (To_Base (Get_Option_Class (Ctx))) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Debugging_And_Measurement))
                           and Get_Option_Number (Ctx) = 4)
                          or (RFLX_Types.U64 (To_Base (Get_Option_Class (Ctx))) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                              and (Get_Option_Number (Ctx) = 9
                                   or Get_Option_Number (Ctx) = 3
                                   or Get_Option_Number (Ctx) = 7))
                          or (Get_Option_Length (Ctx) = 11
                              and RFLX_Types.U64 (To_Base (Get_Option_Class (Ctx))) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                              and Get_Option_Number (Ctx) = 2)
                          or (Get_Option_Length (Ctx) = 4
                              and RFLX_Types.U64 (To_Base (Get_Option_Class (Ctx))) = RFLX_Types.U64 (To_Base (RFLX.IPv4.Control))
                              and Get_Option_Number (Ctx) = 8)
                       then
                          Predecessor (Ctx, F_Option_Data) = F_Option_Length
                          and Valid_Next (Ctx, F_Option_Data)),
               when F_Option_Data =>
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

   procedure Set_Copied (Ctx : in out Context; Val : Boolean) is
      Field_Value : constant Field_Dependent_Value := (F_Copied, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.RFLX_Builtin_Types.Boolean_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Copied), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Copied_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Copied;

   procedure Set_Option_Class (Ctx : in out Context; Val : RFLX.IPv4.Option_Class) is
      Field_Value : constant Field_Dependent_Value := (F_Option_Class, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.IPv4.Option_Class_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Option_Class), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Option_Class_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Option_Class;

   procedure Set_Option_Number (Ctx : in out Context; Val : RFLX.IPv4.Option_Number) is
      Field_Value : constant Field_Dependent_Value := (F_Option_Number, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.IPv4.Option_Number);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Option_Number), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Option_Number_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Option_Number;

   procedure Set_Option_Length (Ctx : in out Context; Val : RFLX.IPv4.Option_Length) is
      Field_Value : constant Field_Dependent_Value := (F_Option_Length, To_Base (Val));
      Buffer_First, Buffer_Last : RFLX_Types.Index;
      Offset : RFLX_Types.Offset;
      procedure Insert is new RFLX_Types.Insert (RFLX.IPv4.Option_Length_Base);
   begin
      Set (Ctx, Field_Value, Field_Size (Ctx, F_Option_Length), True, Buffer_First, Buffer_Last, Offset);
      Insert (Field_Value.Option_Length_Value, Ctx.Buffer, Buffer_First, Buffer_Last, Offset, RFLX_Types.High_Order_First);
   end Set_Option_Length;

   procedure Set_Option_Data_Empty (Ctx : in out Context) is
      Unused_First, Unused_Last : RFLX_Types.Bit_Index;
      Unused_Buffer_First, Unused_Buffer_Last : RFLX_Types.Index;
      Unused_Offset : RFLX_Types.Offset;
   begin
      Set (Ctx, (Fld => F_Option_Data), 0, True, Unused_Buffer_First, Unused_Buffer_Last, Unused_Offset);
   end Set_Option_Data_Empty;

   procedure Initialize_Option_Data_Private (Ctx : in out Context; Length : RFLX_Types.Length) with
     Pre =>
       not Ctx'Constrained
       and then Has_Buffer (Ctx)
       and then Valid_Next (Ctx, F_Option_Data)
       and then Valid_Length (Ctx, F_Option_Data, Length)
       and then RFLX_Types.To_Length (Available_Space (Ctx, F_Option_Data)) >= Length
       and then Field_First (Ctx, F_Option_Data) mod RFLX_Types.Byte'Size = 1,
     Post =>
       Has_Buffer (Ctx)
       and Structural_Valid (Ctx, F_Option_Data)
       and Field_Size (Ctx, F_Option_Data) = RFLX_Types.To_Bit_Length (Length)
       and Ctx.Verified_Last = Field_Last (Ctx, F_Option_Data)
       and Ctx.Buffer_First = Ctx.Buffer_First'Old
       and Ctx.Buffer_Last = Ctx.Buffer_Last'Old
       and Ctx.First = Ctx.First'Old
       and Ctx.Last = Ctx.Last'Old
       and Predecessor (Ctx, F_Option_Data) = Predecessor (Ctx, F_Option_Data)'Old
       and Valid_Next (Ctx, F_Option_Data) = Valid_Next (Ctx, F_Option_Data)'Old
       and Get_Copied (Ctx) = Get_Copied (Ctx)'Old
       and Get_Option_Class (Ctx) = Get_Option_Class (Ctx)'Old
       and Get_Option_Number (Ctx) = Get_Option_Number (Ctx)'Old
       and Get_Option_Length (Ctx) = Get_Option_Length (Ctx)'Old
   is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Option_Data);
      Last : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Option_Data) + RFLX_Types.Bit_Length (Length) * RFLX_Types.Byte'Size - 1;
   begin
      pragma Assert (Last mod RFLX_Types.Byte'Size = 0);
      Reset_Dependent_Fields (Ctx, F_Option_Data);
      pragma Warnings (Off, "attribute Update is an obsolescent feature");
      Ctx := Ctx'Update (Verified_Last => Last, Written_Last => Last);
      pragma Warnings (On, "attribute Update is an obsolescent feature");
      Ctx.Cursors (F_Option_Data) := (State => S_Structural_Valid, First => First, Last => Last, Value => (Fld => F_Option_Data), Predecessor => Ctx.Cursors (F_Option_Data).Predecessor);
      Ctx.Cursors (Successor (Ctx, F_Option_Data)) := (State => S_Invalid, Predecessor => F_Option_Data);
   end Initialize_Option_Data_Private;

   procedure Initialize_Option_Data (Ctx : in out Context) is
   begin
      Initialize_Option_Data_Private (Ctx, RFLX_Types.To_Length (Field_Size (Ctx, F_Option_Data)));
   end Initialize_Option_Data;

   procedure Set_Option_Data (Ctx : in out Context; Data : RFLX_Types.Bytes) is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Option_Data);
      Buffer_First : constant RFLX_Types.Index := RFLX_Types.To_Index (First);
      Buffer_Last : constant RFLX_Types.Index := Buffer_First + Data'Length - 1;
   begin
      Initialize_Option_Data_Private (Ctx, Data'Length);
      Ctx.Buffer.all (Buffer_First .. Buffer_Last) := Data;
   end Set_Option_Data;

   procedure Generic_Set_Option_Data (Ctx : in out Context; Length : RFLX_Types.Length) is
      First : constant RFLX_Types.Bit_Index := Field_First (Ctx, F_Option_Data);
      Buffer_First : constant RFLX_Types.Index := RFLX_Types.To_Index (First);
      Buffer_Last : constant RFLX_Types.Index := RFLX_Types.To_Index (First + RFLX_Types.To_Bit_Length (Length) - 1);
   begin
      Process_Option_Data (Ctx.Buffer.all (Buffer_First .. Buffer_Last));
      Initialize_Option_Data_Private (Ctx, Length);
   end Generic_Set_Option_Data;

end RFLX.IPv4.Option;
