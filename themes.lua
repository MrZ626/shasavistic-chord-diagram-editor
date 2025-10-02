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
            { COLOR.HEX 'FFFFFFFF' }, -- 1
            { COLOR.HEX 'F27992FF' }, -- 2
            { COLOR.HEX '6CD985FF' }, -- 3
            { COLOR.HEX 'B598EEFF' }, -- 4
            { COLOR.HEX 'FFC247FF' }, -- 5
            { COLOR.HEX 'EA6FC9FF' }, -- 6
            { COLOR.HEX '93F6B8FF' }, -- 7
            { COLOR.HEX '72AFE8FF' }, -- 8
            { COLOR.HEX '72E0D5FF' }, -- 9
            { COLOR.HEX 'FF7DD2FF' }, -- 10
            { COLOR.HEX 'FEB3FFFF' }, -- 11
            { COLOR.HEX '90F196FF' }, -- 12 unofficial from here
            { COLOR.HEX 'ABCC5AFF' }, -- 13
            { COLOR.HEX 'D4CC57FF' }, -- 14
            { COLOR.HEX 'F09E65FF' }, -- 15
            { COLOR.HEX 'E075DAFF' }, -- 16
            { COLOR.HEX '9192F6FF' }, -- 17
            { COLOR.HEX '84B1F8FF' }, -- 18
            { COLOR.HEX '8FF3D7FF' }, -- 19
            { COLOR.HEX '91F7BAFF' }, -- 20
            { COLOR.HEX '91F39EFF' }, -- 21
            { COLOR.HEX '92D973FF' }, -- 22
            { COLOR.HEX 'A9CD5CFF' }, -- 23
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA42' }, -- 1
            { COLOR.HEX 'F2799226' }, -- 2
            { COLOR.HEX '2FD65626' }, -- 3
            { COLOR.HEX 'AA88EE26' }, -- 4
            { COLOR.HEX 'FFAA0126' }, -- 5
            { COLOR.HEX 'EA6FC926' }, -- 6
            { COLOR.HEX '93F6B826' }, -- 7
            { COLOR.HEX '72AFE826' }, -- 8
            { COLOR.HEX '72E0D526' }, -- 9
            { COLOR.HEX 'FF7DD226' }, -- 10
            { COLOR.HEX 'FEB3FF26' }, -- 11
            { COLOR.HEX '90F19626' }, -- 12 unofficial from here
            { COLOR.HEX 'ABCC5A26' }, -- 13
            { COLOR.HEX 'D4CC5726' }, -- 14
            { COLOR.HEX 'F09E6526' }, -- 15
            { COLOR.HEX 'E075DA26' }, -- 16
            { COLOR.HEX '9192F626' }, -- 17
            { COLOR.HEX '84B1F826' }, -- 18
            { COLOR.HEX '8FF3D726' }, -- 19
            { COLOR.HEX '91F7BA26' }, -- 20
            { COLOR.HEX '91F39E26' }, -- 21
            { COLOR.HEX '92D97326' }, -- 22
            { COLOR.HEX 'A9CD5C26' }, -- 23
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
            { COLOR.HEX 'FFFFFFFF' }, -- 1
            { COLOR.HEX 'F27992FF' }, -- 2
            { COLOR.HEX '17AB39FF' }, -- 3
            { COLOR.HEX 'AA88EEFF' }, -- 4
            { COLOR.HEX 'EA9C02FF' }, -- 5
            { COLOR.HEX 'EA6FC9FF' }, -- 6
            { COLOR.HEX '75DB9AFF' }, -- 7
            { COLOR.HEX '5E9FDBFF' }, -- 8
            { COLOR.HEX '59C0B5FF' }, -- 9
            { COLOR.HEX 'DB66B2FF' }, -- 10
            { COLOR.HEX 'DA7FDBFF' }, -- 11
            { COLOR.HEX '90F196FF' }, -- 12 unofficial from here
            { COLOR.HEX 'ABCC5AFF' }, -- 13
            { COLOR.HEX 'D4CC57FF' }, -- 14
            { COLOR.HEX 'F09E65FF' }, -- 15
            { COLOR.HEX 'E075DAFF' }, -- 16
            { COLOR.HEX '9192F6FF' }, -- 17
            { COLOR.HEX '84B1F8FF' }, -- 18
            { COLOR.HEX '8FF3D7FF' }, -- 19
            { COLOR.HEX '91F7BAFF' }, -- 20
            { COLOR.HEX '91F39EFF' }, -- 21
            { COLOR.HEX '92D973FF' }, -- 22
            { COLOR.HEX 'A9CD5CFF' }, -- 23
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA62' }, -- 1
            { COLOR.HEX 'F2799262' }, -- 2
            { COLOR.HEX '6CD98562' }, -- 3
            { COLOR.HEX 'B598EE62' }, -- 4
            { COLOR.HEX 'FFC24762' }, -- 5
            { COLOR.HEX 'EA6FC962' }, -- 6
            { COLOR.HEX '75DB9A62' }, -- 7
            { COLOR.HEX '5E9FDB62' }, -- 8
            { COLOR.HEX '59C0B562' }, -- 9
            { COLOR.HEX 'DB66B262' }, -- 10
            { COLOR.HEX 'DA7FDB62' }, -- 11
            { COLOR.HEX '90F19626' }, -- 12 unofficial from here
            { COLOR.HEX 'ABCC5A26' }, -- 13
            { COLOR.HEX 'D4CC5726' }, -- 14
            { COLOR.HEX 'F09E6526' }, -- 15
            { COLOR.HEX 'E075DA26' }, -- 16
            { COLOR.HEX '9192F626' }, -- 17
            { COLOR.HEX '84B1F826' }, -- 18
            { COLOR.HEX '8FF3D726' }, -- 19
            { COLOR.HEX '91F7BA26' }, -- 20
            { COLOR.HEX '91F39E26' }, -- 21
            { COLOR.HEX '92D97326' }, -- 22
            { COLOR.HEX 'A9CD5C26' }, -- 23
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
