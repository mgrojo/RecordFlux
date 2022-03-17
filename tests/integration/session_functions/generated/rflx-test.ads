pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");
with RFLX.RFLX_Types;

package RFLX.Test with
  SPARK_Mode
is

   type Result is (M_Valid, M_Invalid) with
     Size =>
       2;
   for Result use (M_Valid => 0, M_Invalid => 1);

   function Valid_Result (Val : RFLX.RFLX_Types.U64) return Boolean is
     (Val in 0 | 1);

   function To_U64 (Enum : RFLX.Test.Result) return RFLX.RFLX_Types.U64 is
     ((case Enum is
          when M_Valid =>
             0,
          when M_Invalid =>
             1));

   pragma Warnings (Off, "unreachable branch");

   function To_Actual (Val : RFLX.RFLX_Types.U64) return RFLX.Test.Result is
     ((case Val is
          when 0 =>
             M_Valid,
          when 1 =>
             M_Invalid,
          when others =>
             RFLX.Test.Result'Last))
    with
     Pre =>
       Valid_Result (Val);

   pragma Warnings (On, "unreachable branch");

end RFLX.Test;
