# # proc print(value: bool) {.importc, cdecl}

# type
#   SyncCommitteePeriod* = distinct uint64
#   Slot* = distinct uint64

# const
#   FAR_FUTURE_SLOT* = Slot(not 0'u64)
#   SLOTS_PER_EPOCH* {.intdefine.}: uint64 = 32
#   EPOCHS_PER_SYNC_COMMITTEE_PERIOD* {.intdefine.}: uint64 = 256

#   SLOTS_PER_SYNC_COMMITTEE_PERIOD* =
#     SLOTS_PER_EPOCH * EPOCHS_PER_SYNC_COMMITTEE_PERIOD

#   FAR_FUTURE_PERIOD* = SyncCommitteePeriod(not 0'u64)


# template ethTimeUnit*(typ: type) {.dirty.} =
#   proc `+`*(x: typ, y: uint64): typ {.borrow, noSideEffect.}
#   proc `-`*(x: typ, y: uint64): typ {.borrow, noSideEffect.}
#   proc `-`*(x: uint64, y: typ): typ {.borrow, noSideEffect.}

#   # Not closed over type in question (Slot or Epoch)
#   proc `mod`*(x: typ, y: uint64): uint64 {.borrow, noSideEffect.}
#   proc `div`*(x: typ, y: uint64): uint64 {.borrow, noSideEffect.}
#   proc `div`*(x: uint64, y: typ): uint64 {.borrow, noSideEffect.}
#   proc `-`*(x: typ, y: typ): uint64 {.borrow, noSideEffect.}

#   proc `*`*(x: typ, y: uint64): uint64 {.borrow, noSideEffect.}

#   proc `+=`*(x: var typ, y: typ) {.borrow, noSideEffect.}
#   proc `+=`*(x: var typ, y: uint64) {.borrow, noSideEffect.}
#   proc `-=`*(x: var typ, y: typ) {.borrow, noSideEffect.}
#   proc `-=`*(x: var typ, y: uint64) {.borrow, noSideEffect.}

#   # Comparison operators
#   proc `<`*(x: typ, y: typ): bool {.borrow, noSideEffect.}
#   proc `<`*(x: typ, y: uint64): bool {.borrow, noSideEffect.}
#   proc `<`*(x: uint64, y: typ): bool {.borrow, noSideEffect.}
#   proc `<=`*(x: typ, y: typ): bool {.borrow, noSideEffect.}
#   proc `<=`*(x: typ, y: uint64): bool {.borrow, noSideEffect.}
#   proc `<=`*(x: uint64, y: typ): bool {.borrow, noSideEffect.}

#   proc `==`*(x: typ, y: typ): bool {.borrow, noSideEffect.}
#   proc `==`*(x: typ, y: uint64): bool {.borrow, noSideEffect.}
#   proc `==`*(x: uint64, y: typ): bool {.borrow, noSideEffect.}

# ethTimeUnit Slot

# template sync_committee_period*(slot: Slot): SyncCommitteePeriod =
#   if slot == FAR_FUTURE_SLOT: FAR_FUTURE_PERIOD
#   else: SyncCommitteePeriod(slot div SLOTS_PER_SYNC_COMMITTEE_PERIOD)

# echo(cast[uint64] (1179007.Slot.sync_committee_period))
# echo(cast[uint64] (1173120.Slot.sync_committee_period))

import  std/options
import light_client_utils
import blscurve


# {.emit: """
# int blst_p1_affine_is_inf(const int p)
# {    int a = sizeof(p);
#     // POINTonE1 P;

#     // vec_copy(P.X, p->X, 2*sizeof(P.X));
#     // vec_select(P.Z, p->X, BLS12_381_Rx.p, sizeof(P.Z),
#     //                  vec_is_zero(p, sizeof(*p)));

#     // return (int)POINTonE1_in_G1(&P);
#     return a/a;   }

# int blst_p1_affine_in_g1(const int p)
# {
#     int a = sizeof(p);
#     // POINTonE1 P;

#     // vec_copy(P.X, p->X, 2*sizeof(P.X));
#     // vec_select(P.Z, p->X, BLS12_381_Rx.p, sizeof(P.Z),
#     //                  vec_is_zero(p, sizeof(*p)));

#     // return (int)POINTonE1_in_G1(&P);
#     return a/a;
# }

# bool fromBytes(int obj) {
# 	NIM_BOOL result;
# 	NIM_BOOL varResult;
# 	NIM_BOOL T1_;
# 	int T3_;
# 	NIM_BOOL T4_;
# 	int T6_;
# {	result = (NIM_BOOL)0;
# 	varResult = NIM_TRUE;
# 	T1_ = (NIM_BOOL)0;
# 	T1_ = varResult;
# 	if (!(T1_)) goto LA2_;
# 	T3_ = (int)0;
# 	T3_ = blst_p1_affine_is_inf(obj);
# 	T1_ = !(((T3_) != 0));
# 	LA2_: ;
# 	varResult = T1_;
# 	T4_ = (NIM_BOOL)0;
# 	T4_ = varResult;
# 	if (!(T4_)) goto LA5_;
# 	T6_ = (int)0;
# 	T6_ = blst_p1_affine_in_g1(obj);
# 	T4_ = ((T6_) != 0);
# 	LA5_: ;
# 	varResult = T4_;
# 	result = varResult;
# 	goto BeforeRet_;
# 	}BeforeRet_: ;
# 	return result;
# }
# """.}

# func a*(v: ValidatorPubKey): Option[CookedPubKey] {.cdecl, exportc, dynlib} =
#   ## Parse signature blob - this may fail
#   var val: blscurve.PublicKey
#   if fromBytes(val, v.blob):
#     some CookedPubKey(val)
#   else:
#     none CookedPubKey

# proc a*(v: int): bool {.cdecl, exportc, dynlib} =
#   proc fromBytes(arg: int):bool {.importc.}
#   if fromBytes(5):
#     return true

#   discard

proc a*(v: ValidatorPubKey): CookedPubKey {.cdecl, exportc, dynlib} =
  # proc fromBytes(arg: int):bool {.importc.}
  # if fromBytes(5):
  #   return true
  ## Parse signature blob - this may fail
  var val: blscurve.PublicKey

  if fromBytes(val, v.blob):
    return CookedPubKey(val)
    # return CookedPubKey(val)
  else:
    return CookedPubKey(val)

  discard

