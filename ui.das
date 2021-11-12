//options persistent_heap = true
//options gc

//module ui shared

require daslib/media

struct Element
    text:string
    action:lambda<():void>
    children:array<Element?>


var root: Element?
var showMenu = true
var curItem = 0


def make_main_menu : Element?
    var continueCb <- @ <| ():void
        showMenu = false

    var miContinue <- new [[Element text="Continue", action <- continueCb]]

    var chooseLevelCb <- @ <| ():void
        pass

    var miChooseLevel <- new [[Element text="Choose level", action <- chooseLevelCb]]

    var exitCb <- @ <| ():void
        schedule_quit_game()

    var miExit <- new [[Element text="Exit", action <- exitCb]]

    var root <- new [[Element
        children <- to_array_move([[Element?
            miContinue;
            miChooseLevel;
            miExit
        ]])
    ]]

    return root


def on_key(pressed:bool; key:int)
    if pressed
        if key==VK_UP
            curItem = (curItem - 1 + length(root.children)) % length(root.children)
        elif key == VK_DOWN
            curItem = (curItem + 1) % length(root.children)
        elif key == VK_RETURN
            invoke(root.children[curItem].action)
        elif key == VK_ESCAPE
            showMenu = !showMenu


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
    if root == null
        root = make_main_menu()

    let sw = get_screen_width()
    let sh = get_screen_height()
    let screensz = float2(sw, sh)
    var y = sh/4
    let fontSize = sh/20
    set_font_size(fontSize)

    fill_rect(0, 0, sw, sh, 0xA05050A0)

    for item, idx in root.children, range(length(root.children))
        let isCurrent = idx == curItem
        let bounds = get_text_size(item.text)
        let color = isCurrent ? 0xFFFFFFFF : 0xA0A0A0A0
        text_out((screensz[0]-bounds[0])/2.0f, float(y), item.text, color)
        y += fontSize * 3 / 2

