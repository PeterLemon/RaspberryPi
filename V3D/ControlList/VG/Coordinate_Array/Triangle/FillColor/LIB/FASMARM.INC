macro imm16 reg,immediate {
  mov reg,(immediate) and $FF
  orr reg,(immediate) and $FF00
}

macro imm16eq reg,immediate {
  moveq reg,(immediate) and $FF
  orreq reg,(immediate) and $FF00
}

macro imm16ne reg,immediate {
  movne reg,(immediate) and $FF
  orrne reg,(immediate) and $FF00
}

macro imm16lt reg,immediate {
  movlt reg,(immediate) and $FF
  orrlt reg,(immediate) and $FF00
}

macro imm16gt reg,immediate {
  movgt reg,(immediate) and $FF
  orrgt reg,(immediate) and $FF00
}

macro imm32 reg,immediate {
  mov reg,(immediate) and $FF
  orr reg,(immediate) and $FF00
  orr reg,(immediate) and $FF0000
  orr reg,(immediate) and $FF000000
}

macro imm32eq reg,immediate {
  moveq reg,(immediate) and $FF
  orreq reg,(immediate) and $FF00
  orreq reg,(immediate) and $FF0000
  orreq reg,(immediate) and $FF000000
}

macro imm32ne reg,immediate {
  movne reg,(immediate) and $FF
  orrne reg,(immediate) and $FF00
  orrne reg,(immediate) and $FF0000
  orrne reg,(immediate) and $FF000000
}

macro imm32lt reg,immediate {
  movlt reg,(immediate) and $FF
  orrlt reg,(immediate) and $FF00
  orrlt reg,(immediate) and $FF0000
  orrlt reg,(immediate) and $FF000000
}

macro imm32gt reg,immediate {
  movgt reg,(immediate) and $FF
  orrgt reg,(immediate) and $FF00
  orrgt reg,(immediate) and $FF0000
  orrgt reg,(immediate) and $FF000000
}