pragma Style_Checks ("N3aAbcdefhiIklnOprStux");
pragma Warnings (Off, "redundant conversion");
with RFLX.RFLX_Types;

package RFLX.Ethernet with
  SPARK_Mode
is

   type Address is mod 2**48 with
     Size =>
       48;

   use type RFLX.RFLX_Types.U64;

   function Valid_Address (Val : RFLX.RFLX_Types.U64) return Boolean is
     (Val <= 281474976710655);

   function To_U64 (Val : RFLX.Ethernet.Address) return RFLX.RFLX_Types.U64 is
     (RFLX.RFLX_Types.U64 (Val));

   function To_Actual (Val : RFLX.RFLX_Types.U64) return RFLX.Ethernet.Address is
     (RFLX.Ethernet.Address (Val))
    with
     Pre =>
       Valid_Address (Val);

   type Type_Length is range 46 .. 2**16 - 1 with
     Size =>
       16;

   function Valid_Type_Length (Val : RFLX.RFLX_Types.U64) return Boolean is
     (Val >= 46
      and Val <= 65535);

   function To_U64 (Val : RFLX.Ethernet.Type_Length) return RFLX.RFLX_Types.U64 is
     (RFLX.RFLX_Types.U64 (Val));

   function To_Actual (Val : RFLX.RFLX_Types.U64) return RFLX.Ethernet.Type_Length is
     (RFLX.Ethernet.Type_Length (Val))
    with
     Pre =>
       Valid_Type_Length (Val);

   type TPID is range 16#8100# .. 16#8100# with
     Size =>
       16;

   function Valid_TPID (Val : RFLX.RFLX_Types.U64) return Boolean is
     (Val = 16#8100#);

   function To_U64 (Val : RFLX.Ethernet.TPID) return RFLX.RFLX_Types.U64 is
     (RFLX.RFLX_Types.U64 (Val));

   function To_Actual (Val : RFLX.RFLX_Types.U64) return RFLX.Ethernet.TPID is
     (RFLX.Ethernet.TPID (Val))
    with
     Pre =>
       Valid_TPID (Val);

   type TCI is mod 2**16 with
     Size =>
       16;

   function Valid_TCI (Val : RFLX.RFLX_Types.U64) return Boolean is
     (Val <= 65535);

   function To_U64 (Val : RFLX.Ethernet.TCI) return RFLX.RFLX_Types.U64 is
     (RFLX.RFLX_Types.U64 (Val));

   function To_Actual (Val : RFLX.RFLX_Types.U64) return RFLX.Ethernet.TCI is
     (RFLX.Ethernet.TCI (Val))
    with
     Pre =>
       Valid_TCI (Val);

end RFLX.Ethernet;
