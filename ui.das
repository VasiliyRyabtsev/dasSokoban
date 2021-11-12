//options persistent_heap = true
//options gc

//module ui shared

require daslib/media
require levels
require game


struct Element
    text:string
    action:lambda<():void>
    onCancel:lambda<():void>
    children:array<Element?>


var ui_root: Element?

var curItem = 0


def make_main_menu : Element?
    var continueCb <- @ <| ():void
        ui_root = null

    var miContinue <- new [[Element text="Continue", action <- continueCb]]

    var chooseLevelCb <- @ <| ():void
        ui_root = make_levels_list()

    var miChooseLevel <- new [[Element text="Choose level", action <- chooseLevelCb]]

    var exitCb <- @ <| ():void
        schedule_quit_game()

    var miExit <- new [[Element text="Exit", action <- exitCb]]

    var closeMenu <- @ <| ():void
        ui_root = null

    var ui_root <- new [[Element
        children <- to_array_move([[Element?
            miContinue;
            miChooseLevel;
            miExit
        ]]),
        onCancel <- closeMenu
    ]]

    curItem = 0

    return ui_root


def make_levels_list
    var children:array<Element?>
    children |> resize(length(levels_src))
    for level, idx in levels_src, range(length(levels_src))
        let solvedLabel = was_level_solved(idx) ? " (solved)" : ""
        var action <- @ <| ():void
            start_level(idx)
            ui_root = null

        children[idx] = new [[Element text="Level {idx+1}{solvedLabel}", action <- action]]

    var backToMainMenu <- @ <| ():void
        ui_root = make_main_menu()

    var ui_root <- new [[Element
        children <- children,
        onCancel <- backToMainMenu
    ]]

    curItem = cur_level

    return ui_root


def on_key(pressed:bool; key:int)
    if ui_root==null
        if pressed && key == VK_ESCAPE
            ui_root = make_main_menu()
        return

    if pressed
        if key==VK_UP
            curItem = (curItem - 1 + length(ui_root.children)) % length(ui_root.children)
        elif key == VK_DOWN
            curItem = (curItem + 1) % length(ui_root.children)
        elif key == VK_PRIOR
            curItem = max(curItem-10, 0)
        elif key == VK_NEXT
            curItem = min(curItem+10, length(ui_root.children)-1)
        elif key == VK_RETURN
            invoke(ui_root.children[curItem].action)
        elif key == VK_ESCAPE
            invoke(ui_root.onCancel)


let DASBOX_KB_RANGE_START = 1000

def send_kb_events
    let gen <- generator<tuple<pressed:bool; key:int>>() <| $()
        for key in range(DASBOX_KB_RANGE_START, DASBOX_KB_RANGE_START+128)
            if get_key_down(key)
                yield [[auto true, key]]
            if get_key_up(key)
                yield [[auto false, key]]
        return false

    for e in gen
        on_key(e.pressed, e.key)


def act_ui(dt: float)
    send_kb_events()


def draw_menu
    if ui_root==null
        return

    let sw = get_screen_width()
    let sh = get_screen_height()
    let screensz = float2(sw, sh)
    var y = sh/4
    let fontSize = sh/20
    let lineHeight = fontSize * 3 / 2
    set_font_size(fontSize)

    fill_rect(0, 0, sw, sh, 0xA05050A0)

    let nItems = length(ui_root.children)
    if nItems * lineHeight > sh/2
        y = sh/2 - lineHeight - lineHeight * curItem

    for item, idx in ui_root.children, range(nItems)
        let isCurrent = idx == curItem
        let bounds = get_text_size(item.text)
        let color = isCurrent ? 0xFFFFFFFF : 0xA0A0A0A0
        text_out((screensz[0]-bounds[0])/2.0f, float(y), item.text, color)
        y += lineHeight

