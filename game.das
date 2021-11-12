require strings
require daslib/strings_boost

require levels

let
    WALL   = 0x1
    BOX    = 0x2
    TARGET = 0x4

var cur_level = 0
var level:array<array<uint>>

let cellTypeMap:table<int; uint> <- {{'#' => WALL; '$' => BOX; '.' => TARGET; ' ' => 0u; '@' => 0u}}

var charPos = int2(-1, -1)
var charDir = 2 // clockwise starting from up=0
let dirDeltaPos <- [[int2[] int2(-1,0); int2(0,1); int2(1,0); int2(0,-1)]]

struct HistoryRec
    dir:int
    movedBox:bool

var history:array<HistoryRec>
var levelCompleted = false
var levelWasSolved = false


var stepTransitionT = 0.0f
var animPos = 0.0f


def resolve_cell_char(cell_char)
    let val = cellTypeMap |> find(cell_char) ?? 0xFF00u
    if val == 0xFF00u
        panic("Unexpected char '%c' in level source" |> format(cell_char))
    return val


def parse_level(src)
    var levelArr <- [{for row in src;
        [{for cell in row;
            resolve_cell_char(cell)
        }]
    }]
    return <- levelArr


def parse_char_pos(src)
    let y = find_index_if(src) <| $(row) {return find(row, '@')>=0;}
    let x = find(src[y], '@')
    return <- int2(y, x)


def start_level(n)
    cur_level = n
    level <- parse_level(levels_src[n])
    charPos = parse_char_pos(levels_src[n])
    history |> clear()
    stepTransitionT = 0.0f
    levelCompleted = false
    levelWasSolved = was_level_solved(n)
