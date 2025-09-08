// Text expansion symbols generator
local arrows = {
  // Basic arrows
  '->': '→',
  '<-': '←',
  '^': '↑',
  v: '↓',
  '<->': '↔',

  // Double arrows
  '=>': '⇒',
  '<=': '⇐',
  '<=>': '⇔',

  // Diagonal arrows
  '^^': '↗',
  vv: '↘',
  '^v': '↖',
  'v^': '↙',
};

local math = {
  // Comparison operators
  '!=': '≠',
  '<=': '≤',
  '>=': '≥',
  '~~': '≈',
  '===': '≡',

  // Math operators
  '+-': '±',
  '-+': '∓',
  '#div': '÷',
  '#frac': '⁄',

  // Special values
  '#inf': '∞',
  '#sum': '∑',
  '#prod': '∏',
  '#int': '∫',
  '#sqrt': '√',
  '#cbrt': '∛',
};

// Generate Greek letters
local greekLetters = {
  '#alpha': 'α',
  '#beta': 'β',
  '#gamma': 'γ',
  '#delta': 'δ',
  '#epsilon': 'ε',
  '#zeta': 'ζ',
  '#eta': 'η',
  '#theta': 'θ',
  '#iota': 'ι',
  '#kappa': 'κ',
  '#lambda': 'λ',
  '#mu': 'μ',
  '#nu': 'ν',
  '#xi': 'ξ',
  '#omicron': 'ο',
  '#pi': 'π',
  '#rho': 'ρ',
  '#sigma': 'σ',
  '#tau': 'τ',
  '#upsilon': 'υ',
  '#phi': 'φ',
  '#chi': 'χ',
  '#psi': 'ψ',
  '#omega': 'ω',
};

// Generate subscripts and superscripts
local subscripts = {
  ['#sub' + std.toString(i)]: std.char(8320 + i)
  for i in std.range(0, 9)
};

local superscripts = {
  ['#sup' + std.toString(i)]: (
    if i == 0 then '⁰'
    else if i == 1 then '¹'
    else if i == 2 then '²'
    else if i == 3 then '³'
    else std.char(8304 + i)
  )
  for i in std.range(0, 9)
};

local fractions = {
  '#1/2': '½',
  '#1/3': '⅓',
  '#2/3': '⅔',
  '#1/4': '¼',
  '#3/4': '¾',
  '#1/5': '⅕',
  '#2/5': '⅖',
  '#3/5': '⅗',
  '#4/5': '⅘',
  '#1/6': '⅙',
  '#5/6': '⅚',
  '#1/8': '⅛',
  '#3/8': '⅜',
  '#5/8': '⅝',
  '#7/8': '⅞',
};

local symbols = {
  // Legal/trademark
  '(tm)': '™',
  '(reg)': '®',
  '(copy)': '©',
  '(para)': '¶',
  '(sect)': '§',

  // Units/science
  '(deg)': '°',

  // Currency
  '(eur)': '€',
  '(yen)': '¥',

  // Decorative
  '#bullet': '•',
  '#circle': '○',
  '#dot': '·',
  '#star': '★',
  '#heart': '♥',
  '#spade': '♠',
  '#club': '♣',
  '#diamond': '♦',
  '#check': '✓',
  '#cross': '✗',
  '#tick': '✓',

  // Typography
  '#...': '…',
  '#--': '—',
};

local emails = {
  'b@b': 'bailey@busc.dev',
  'b@g': 'bailey@glimp.se',
  'bjb@': 'bjbuscarino@gmail.com',
};

// Combine all expansions
arrows + math + greekLetters + subscripts + superscripts + fractions + symbols + emails
