-- Apple Magic Keyboard (US) layout
-- Each row is a list of keys with: key (lowercase), label (display), w (width in units, default 1)
-- Total width per row: 14.5 units

return {
    name = "Apple Magic Keyboard (US)",
    rows = {
        -- Number row
        {
            {key="`", w=1}, {key="1", w=1}, {key="2", w=1}, {key="3", w=1},
            {key="4", w=1}, {key="5", w=1}, {key="6", w=1}, {key="7", w=1},
            {key="8", w=1}, {key="9", w=1}, {key="0", w=1}, {key="-", w=1},
            {key="=", w=1}, {key="delete", label="\u{232B}", w=1.5},
        },
        -- QWERTY row
        {
            {key="tab", label="\u{21E5}", w=1.5}, {key="q", w=1}, {key="w", w=1},
            {key="e", w=1}, {key="r", w=1}, {key="t", w=1}, {key="y", w=1},
            {key="u", w=1}, {key="i", w=1}, {key="o", w=1}, {key="p", w=1},
            {key="[", w=1}, {key="]", w=1}, {key="\\", w=1},
        },
        -- Home row
        {
            {key="caps", label="\u{21EA}", w=1.75}, {key="a", w=1}, {key="s", w=1},
            {key="d", w=1}, {key="f", w=1}, {key="g", w=1}, {key="h", w=1},
            {key="j", w=1}, {key="k", w=1}, {key="l", w=1}, {key=";", w=1},
            {key="'", w=1}, {key="return", label="\u{23CE}", w=1.75},
        },
        -- Bottom alpha row
        {
            {key="shift_l", label="\u{21E7}", w=2.25, modifier="shift_l"}, {key="z", w=1}, {key="x", w=1},
            {key="c", w=1}, {key="v", w=1}, {key="b", w=1}, {key="n", w=1},
            {key="m", w=1}, {key=",", w=1}, {key=".", w=1}, {key="/", w=1},
            {key="shift_r", label="\u{21E7}", w=2.25},
        },
        -- Modifier row
        {
            {key="fn", label="fn", w=1.25},
            {key="ctrl_l", label="\u{2303}", w=1.25, modifier="ctrl_l"},
            {key="alt_l", label="\u{2325}", w=1.25, modifier="alt_l"},
            {key="cmd_l", label="\u{2318}", w=1.5, modifier="cmd_l"},
            {key="space", label="", w=5.25},
            {key="cmd_r", label="\u{2318}", w=1.5},
            {key="alt_r", label="\u{2325}", w=1.25},
            {key="left", label="\u{25C0}", w=1.25},
        },
    },
}
