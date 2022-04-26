pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");
with RFLX.RFLX_Types;

package RFLX.Enumeration with
  SPARK_Mode
is

   type Priority_Enum is (Low, Medium, High) with
     Size =>
       8;
   for Priority_Enum use (Low => 1, Medium => 4, High => 7);

   type Priority (Known : Boolean := False) is
      record
         case Known is
            when True =>
               Enum : Priority_Enum;
            when False =>
               Raw : RFLX_Types.S63;
         end case;
      end record;

   use type RFLX.RFLX_Types.S63;

   function Valid_Priority (Val : RFLX.RFLX_Types.S63) return Boolean is
     (Val < 2**8);

   function Valid_Priority (Val : Priority) return Boolean is
     ((if Val.Known then True else Valid_Priority (Val.Raw) and Val.Raw not in 1 | 4 | 7));

   function To_S63 (Enum : RFLX.Enumeration.Priority_Enum) return RFLX.RFLX_Types.S63 is
     ((case Enum is
          when Low =>
             1,
          when Medium =>
             4,
          when High =>
             7));

   function To_Actual (Enum : Priority_Enum) return RFLX.Enumeration.Priority is
     ((True, Enum));

   function To_Actual (Val : RFLX.RFLX_Types.S63) return RFLX.Enumeration.Priority is
     ((case Val is
          when 1 =>
             (True, Low),
          when 4 =>
             (True, Medium),
          when 7 =>
             (True, High),
          when others =>
             (False, Val)))
    with
     Pre =>
       Valid_Priority (Val);

   function To_S63 (Val : RFLX.Enumeration.Priority) return RFLX.RFLX_Types.S63 is
     ((if Val.Known then To_S63 (Val.Enum) else Val.Raw));

end RFLX.Enumeration;
