require strings
require daslib/media

require levels

var imgCrate <- create_image("resources/crate.png")
let imgBrick <- create_image("resources/bricks.png")
var imgPoint <- create_image("resources/point.png")
var charAtlas <- create_image("resources/char.png")


let
    WALL   = 0x1
    BOX    = 0x2
    TARGET = 0x4

var cur_level = 0
var level:array<array<uint>>

let cellTypeMap:table<int; uint> <- {{'#' => WALL; '$' => BOX; '.' => TARGET}}

var charPos = int2(-1, -1)
var charDir = 2 // clockwise starting from up=0
let dirDeltaPos <- [[int2[] int2(-1,0); int2(0,1); int2(1,0); int2(0,-1)]]


def parse_level(src)
    var levelArr <- [{for row in src;
        [{for cell in row;
            cellTypeMap |> find(cell) ?? 0u
        }]
    }]
    return <- levelArr


def parse_char_pos(src)
    let y = find_index_if(src) <| $(row) {return find(row, '@')>=0;}
    let x = find(src[y], '@')
    return <- int2(y, x)


def level_dim(level)
    return <- int2(level |> length, level[0] |> length)


def start_level(n)
    level <- parse_level(levels_src[n])
    charPos = parse_char_pos(levels_src[n])


[export]
def initialize
    set_window_title("Das Sokoban")
    imgCrate |> set_image_smooth(true)
    imgPoint |> set_image_smooth(true)
    //charAtlas |> set_image_smooth(true)
    start_level(cur_level)


def sample_cell(level, pos)
    return level[pos[0]][pos[1]]


[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
        return

    if get_key_down(VK_R)
        start_level(cur_level)
        return

    if get_key_down(VK_COMMA)
        cur_level = (cur_level-1+(levels_src |> length)) % (levels_src |> length)
        start_level(cur_level)
        return

    if get_key_down(VK_PERIOD)
        cur_level = (cur_level+1) % (levels_src |> length)
        start_level(cur_level)
        return


    var needMove = true
    if get_key_down(VK_UP)      { charDir = 0; }
    elif get_key_down(VK_RIGHT) { charDir = 1; }
    elif get_key_down(VK_DOWN)  { charDir = 2; }
    elif get_key_down(VK_LEFT)  { charDir = 3; }
    else
        needMove = false

    let moveDelta = dirDeltaPos[charDir]
    let nextPos <- charPos + moveDelta
    let posAfterNext <- nextPos + moveDelta

    if needMove
        let nextCell = level |> sample_cell(nextPos)
        if (nextCell & WALL)!=0u
            needMove = false
        elif (nextCell & BOX)!=0u
            let cellAfterNext = level |> sample_cell(posAfterNext)
            if (cellAfterNext & (BOX | WALL))!=0u
                needMove = false

        if needMove
            charPos += moveDelta
            if (nextCell & BOX)!=0u
                level[nextPos[0]][nextPos[1]] &= ~BOX
                level[posAfterNext[0]][posAfterNext[1]] |= BOX


def draw_image_at_cell(img, x, y, cellSize, color)
    draw_image(img, float(x*cellSize), float(y*cellSize), color, float2(cellSize, cellSize))


def draw_scene
    let ldim <- level_dim(level)
    let sw = get_screen_width()
    let sh = get_screen_height()
    let cellSize <- min(sw * 8 / (ldim[1] * 10), sh * 8 / (ldim[0] * 10))

    setup_2d_camera(float2(cellSize*ldim[1]/2, cellSize*ldim[0]/2))
    enable_alpha_blend()

    for row, y in level, range(ldim[0])
        for cell, x in row, range(ldim[1])
            if (cell & WALL)!=0u
                imgBrick |> draw_image_at_cell(x, y, cellSize, 0xFFD0D0D0)
            elif (cell & BOX)!=0u
                if (cell & TARGET)!=0u
                    imgCrate |> draw_image_at_cell(x, y, cellSize, 0xFF80A0FF)
                    imgPoint |> draw_image_at_cell(x, y, cellSize, 0xA0C0C0C0)
                else
                    imgCrate |> draw_image_at_cell(x, y, cellSize, 0xFFFFFFFF)
            elif (cell & TARGET)!=0u
                imgPoint |> draw_image_at_cell(x, y, cellSize, 0xFFFFFFFF)

    draw_image_region(charAtlas, float(charPos[1]*cellSize), float(charPos[0]*cellSize),
                        float4(64, 64*charDir, -64, 64), 0xFFFFFFFF, float2(cellSize, cellSize))


def draw_hud
    let sw = get_screen_width()
    let sh = get_screen_height()

    setup_2d_camera(float2(sw/2, sh/2))

    let fontSize = sh/40
    set_font_size(fontSize)

    let pad = sh/80
    text_out(pad, pad, "Level {cur_level+1}", 0xFFFFFFFF)
    text_out(pad, sh-pad-fontSize, "R - reset level, < - prev level, > - next level", 0xFF808080)

    //let get_text_size(text)[1]


[export]
def draw
    draw_scene()
    draw_hud()
