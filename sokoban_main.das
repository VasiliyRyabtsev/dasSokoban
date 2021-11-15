require strings
require daslib/media
require daslib/strings_boost

require levels
require game
require ui

var imgCrate <- create_image("resources/crate.png")
let imgBrick <- create_image("resources/bricks.png")
var imgPoint <- create_image("resources/point.png")
var charAtlas <- create_image("resources/char.png")


[export]
def initialize
    set_window_title("Das Sokoban")
    imgCrate |> set_image_smooth(true)
    imgPoint |> set_image_smooth(true)
    //charAtlas |> set_image_smooth(true)
    start_level(cur_level)


def sample_cell(level, pos)
    return level[pos[0]][pos[1]]


def rollback
    if history |> empty()
        return
    //let dir:int <- history |> pop()
    let step <- history[history |> length() - 1]
    history |> pop()

    charDir = step.dir

    let moveDelta = dirDeltaPos[charDir]

    if step.movedBox
        let boxPos <- charPos + moveDelta
        level[charPos[0]][charPos[1]] |= BOX
        level[boxPos[0]][boxPos[1]] &= ~BOX

    charPos -= moveDelta
    stepTransitionT = 0.0f


def check_completed
    if levelCompleted
        return
    for row in level
        for cell in row
            if (cell & BOX)!=0u && (cell & TARGET)==0u
                return
    levelCompleted = true
    save_level_solved(cur_level)


def change_level(delta)
    start_level((cur_level+delta+length(levels_src)) % length(levels_src))


def act_game(dt: float)
    if get_key_down(VK_R)
        start_level(cur_level)
        return

    if get_key_down(VK_COMMA)
        change_level(-1)
        return

    if get_key_down(VK_PERIOD)
        change_level(1)
        return

    if get_key_down(VK_SPACE) && levelCompleted
        change_level(1)
        return

    if get_key_down(VK_BACK)
        rollback()
        return

    let moveSpeed = 4.0f
    stepTransitionT = max(0.0f, stepTransitionT-moveSpeed*dt)
    if stepTransitionT>0.0f
        let animSpeed = 3.0f
        animPos = (animPos + animSpeed * dt) % 1.0f

    var needMove = false
    if stepTransitionT==0.0f && !levelCompleted
        if   get_key(VK_UP)    { charDir = 0; needMove = true; }
        elif get_key(VK_RIGHT) { charDir = 1; needMove = true; }
        elif get_key(VK_DOWN)  { charDir = 2; needMove = true; }
        elif get_key(VK_LEFT)  { charDir = 3; needMove = true; }

    if needMove
        let moveDelta = dirDeltaPos[charDir]
        let nextPos <- charPos + moveDelta
        let posAfterNext <- nextPos + moveDelta

        let nextCell = level |> sample_cell(nextPos)
        if (nextCell & WALL)!=0u
            needMove = false
        elif (nextCell & BOX)!=0u
            let cellAfterNext = level |> sample_cell(posAfterNext)
            if (cellAfterNext & (BOX | WALL))!=0u
                needMove = false

        if needMove
            charPos += moveDelta
            let moveBox <- (nextCell & BOX)!=0u
            if moveBox
                level[nextPos[0]][nextPos[1]] &= ~BOX
                level[posAfterNext[0]][posAfterNext[1]] |= BOX
            history |> push([[HistoryRec dir=charDir, movedBox=moveBox]])

            stepTransitionT = 1.0f

        check_completed()


[export]
def act(dt: float)
    act_ui(dt)
    if ui_root==null
        act_game(dt)


def is_moving_box
    return !history|>empty() && history[history|>length() - 1].movedBox


def draw_scene
    let ldim <- level_dim(level)
    let sw = get_screen_width()
    let sh = get_screen_height()
    let cellSize <- min(sw * 8 / (ldim[1] * 10), sh * 8 / (ldim[0] * 10))

    setup_2d_camera(float2(ldim[1]/2, ldim[0]/2), float(cellSize))
    enable_alpha_blend()

    let unit = float2(1,1)
    for row, y in level, range(ldim[0])
        for cell, x in row, range(ldim[1])
            var pos <- float2(y, x)
            var boxPos = pos
            if stepTransitionT>0.0f && int2(y,x)==charPos+dirDeltaPos[charDir] && is_moving_box()
                boxPos -= float2(dirDeltaPos[charDir]) * stepTransitionT

            if (cell & WALL)!=0u
                imgBrick |> draw_image(pos[1], pos[0], 0xFFD0D0D0, unit)
            elif (cell & BOX)!=0u
                if (cell & TARGET)!=0u
                    imgCrate |> draw_image(boxPos[1], boxPos[0], 0xFF80A0FF, unit)
                    imgPoint |> draw_image(pos[1], pos[0], 0xA0C0C0C0, unit)
                else
                    imgCrate |> draw_image(boxPos[1], boxPos[0], 0xFFFFFFFF, unit)
            elif (cell & TARGET)!=0u
                imgPoint |> draw_image(pos[1], pos[0], 0xFFFFFFFF, unit)

    let charRenderPos <- float2(charPos) - float2(dirDeltaPos[charDir]) * stepTransitionT
    let nAnimFrames = 9.0
    let frameNo = int(floor(nAnimFrames * animPos))
    draw_image_region(charAtlas, charRenderPos[1], charRenderPos[0],
                        float4(64+64*frameNo, 64*charDir, -64, 64), 0xFFFFFFFF, unit)


def text_centered(y_offs; text; font_size; color=0xFFFFFFFF)
    let screensz = float2(get_screen_width(), get_screen_height())
    set_font_size(font_size)
    let bounds = get_text_size(text)
    text_out((screensz[0]-bounds[0])/2.0f, (screensz[1]-bounds[1])/2.0f+float(y_offs), text, color)


def draw_hud
    let sw = get_screen_width()
    let sh = get_screen_height()

    setup_2d_camera(float2(sw/2, sh/2))

    let fontSize = sh/40
    set_font_size(fontSize)

    let pad = sh/80
    let solvedText = levelWasSolved ? " (solved)" : ""
    text_out(pad, pad, "Level {cur_level+1}{solvedText}", 0xFFFFFFFF)
    text_out(pad, sh-pad-fontSize, "R - reset level, Backspace <- undo, < - prev level, > - next level", 0xFF808080)

    if levelCompleted
        fill_rect(0, 0, sw, sh, 0x50202050)
        text_centered(-fontSize, "Completed!", sh/20)
        text_centered(fontSize, "Press Space to continue", fontSize, 0xC0C0C0C0)



[export]
def draw
    draw_scene()
    draw_hud()
    draw_menu()
