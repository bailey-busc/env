# Implement a maybe type similar to Rust's Option type
_: rec {
  just = v: { just = v; };
  nothing = { };
  maybe = v: if builtins.isNull v then nothing else just v;
  mapOptional = f: v: if v ? just then { just = f v.just; } else nothing;
  unwrap = v: v.just or (builtins.throw "Maybe is nothing");
  unwrapOr = v: default: v.just or default;
  cond = f: v: if (f v) then just v else nothing;
  bind = f: v: if v ? just then f v.just else nothing;
  toList = v: if v ? just then [ v.just ] else [ ];
  filter = pred: v: if v ? just && pred v.just then v else nothing;
  match = v: { just, nothing }: if v ? just then just v.just else nothing;
}
