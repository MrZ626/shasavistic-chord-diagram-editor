local themes = {
    dark = {
        cursorLight1 = { COLOR.HEX 'FFFFFF12' },
        cursorLight2 = { COLOR.HEX 'FFFFFF26' },
        bgbase = { COLOR.HEX '61607BFF' },
        bg = { COLOR.HEX '65647FFF' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'F5C40018' },
        cursor = { COLOR.HEX 'F5C400FF' },
        preview = { COLOR.HEX '00F1F580' },
        playline = { COLOR.HEX 'C0F0FFFF' },
        pitchText = { COLOR.HEX 'FFFFFFD0' },
        text = { COLOR.HEX 'FFFFFF80' },
        note = {
            normal = { COLOR.HEX 'FFFFFFFF' },
            tense = { COLOR.HEX '00FFFFFF' },
            pink = { COLOR.HEX 'F0A3F0FF' },
        },
        dim = {
            { COLOR.HEX 'FFFFFFFF' },
            { COLOR.HEX 'F27992FF' },
            { COLOR.HEX '6CD985FF' },
            { COLOR.HEX 'B598EEFF' },
            { COLOR.HEX 'FFC247FF' },
            { COLOR.HEX 'B5B539FF' },
            { COLOR.HEX 'ED9877FF' },
            { COLOR.HEX 'E8AABCFF' },
            { COLOR.HEX 'EC9CE0FF' },
            -- { COLOR.HEX '7C89EEFF' },
            -- { COLOR.HEX 'D4EC7AFF' },
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA42' },
            { COLOR.HEX 'F2799226' },
            { COLOR.HEX '2FD65626' },
            { COLOR.HEX 'AA88EE26' },
            { COLOR.HEX 'FFAA0126' },
            { COLOR.HEX 'B5B50026' },
            { COLOR.HEX 'ED987726' },
            { COLOR.HEX 'E8AABC26' },
            { COLOR.HEX 'EC9CE026' },
            -- { COLOR.HEX '7C89EE26' },
            -- { COLOR.HEX 'D4EC7A26' },
        },
    },
    bright = {
        cursorLight1 = { COLOR.HEX '00000012' },
        cursorLight2 = { COLOR.HEX '00000026' },
        bgbase = { COLOR.HEX 'DCD3C6FF' },
        bg = { COLOR.HEX 'E8E6E3FF' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'FF312618' },
        cursor = { COLOR.HEX 'FF312680' },
        preview = { COLOR.HEX '2680FF80' },
        playline = { COLOR.HEX '0042D0FF' },
        pitchText = { COLOR.HEX '000000D0' },
        text = { COLOR.HEX '00000080' },
        note = {
            normal = { COLOR.HEX 'AAAAAAFF' },
            tense = { COLOR.HEX '00DDDDFF' },
            pink = { COLOR.HEX 'DE70B6FF' },
        },
        dim = {
            { COLOR.HEX 'FFFFFFFF' },
            { COLOR.HEX 'F27992FF' },
            { COLOR.HEX '17AB39FF' },
            { COLOR.HEX 'AA88EEFF' },
            { COLOR.HEX 'EA9C02FF' },
            { COLOR.HEX 'B5B500FF' },
            { COLOR.HEX 'ED9877FF' },
            { COLOR.HEX 'EE8CA8FF' },
            { COLOR.HEX 'F188E1FF' },
            -- { COLOR.HEX '7C89EEFF' },
            -- { COLOR.HEX 'C2DD63FF' },
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA62' },
            { COLOR.HEX 'F2799262' },
            { COLOR.HEX '6CD98562' },
            { COLOR.HEX 'B598EE62' },
            { COLOR.HEX 'FFC24762' },
            { COLOR.HEX 'B5B50062' },
            { COLOR.HEX 'ED987762' },
            { COLOR.HEX 'EE8CA862' },
            { COLOR.HEX 'F188E162' },
            -- { COLOR.HEX '7C89EE62' },
            -- { COLOR.HEX 'C2DD6362' },
        },
    },
}

local function fadeColor(back, fore, a)
    return {
        fore[1] * a + back[1] * (1 - a),
        fore[2] * a + back[2] * (1 - a),
        fore[3] * a + back[3] * (1 - a)
    }
end
themes.dark.dimFade = {}
for i = 1, #themes.dark.dim do themes.dark.dimFade[i] = fadeColor(themes.dark.bg, themes.dark.dim[i], .42) end
themes.bright.dimFade = {}
for i = 1, #themes.bright.dim do themes.bright.dimFade[i] = fadeColor(themes.bright.bg, themes.bright.dim[i], .42) end

return themes
