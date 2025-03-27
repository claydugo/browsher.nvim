globals = {
    "vim",
    "require",
    "pcall",
    "xpcall",
    "error",
    "assert",
    "type",
    "tostring",
    "tonumber",
    "pairs",
    "ipairs",
    "next",
    "select",
    "unpack",
    "table",
    "string",
    "math",
    "io",
    "os",
    "debug",
    "coroutine"
}

std = "lua54"
max_line_length = 100

ignore = {
    "111", -- setting non-standard global variable
    "112", -- mutating non-standard global variable
    "113", -- accessing undefined variable
    "121", -- setting read-only variable
    "122", -- mutating read-only variable
    "131", -- shadowing definition of variable
    "211", -- variable is set but never accessed
    "212", -- argument is unused
    "213", -- loop variable is unused
    "221", -- variable is never set
    "231", -- variable is never accessed
    "311", -- value assigned to variable is never used
    "312", -- value assigned to variable is overwritten
    "321", -- accessing undefined variable
    "322", -- variable is never accessed
    "323", -- variable is never set
    "324", -- variable is set but never accessed
    "331", -- variable is never accessed
    "332", -- variable is never set
    "411", -- variable is accessed before initialization
    "412", -- variable is overwritten before use
    "421", -- shadowing upvalue
    "422", -- shadowing argument
    "431", -- shadowing local variable
    "432", -- shadowing loop variable
    "433", -- shadowing upvalue
    "434", -- shadowing argument
    "435", -- shadowing local variable
    "436", -- shadowing loop variable
    "511", -- unreachable code
    "512", -- loop is executed at most once
    "521", -- unreachable code
    "522", -- loop is executed at most once
    "531", -- unreachable code
    "532", -- loop is executed at most once
    "541", -- unreachable code
    "542", -- loop is executed at most once
    "551", -- unreachable code
    "552", -- loop is executed at most once
    "561", -- unreachable code
    "562", -- loop is executed at most once
    "571", -- unreachable code
    "572", -- loop is executed at most once
    "581", -- unreachable code
    "582", -- loop is executed at most once
    "591", -- unreachable code
    "592", -- loop is executed at most once
    "611", -- variable is set but never accessed
    "612", -- variable is never accessed
    "613", -- variable is never set
    "614", -- variable is set but never accessed
    "621", -- variable is never accessed
    "622", -- variable is never set
    "623", -- variable is set but never accessed
    "631", -- variable is never accessed
    "632", -- variable is never set
    "641", -- variable is never accessed
    "642", -- variable is never set
    "651", -- variable is never accessed
    "652", -- variable is never set
    "653", -- variable is set but never accessed
    "654", -- variable is never accessed
    "655", -- variable is never set
    "656", -- variable is set but never accessed
    "657", -- variable is never accessed
    "658", -- variable is never set
    "659", -- variable is set but never accessed
    "661", -- variable is never accessed
    "662", -- variable is never set
    "663", -- variable is set but never accessed
    "664", -- variable is never accessed
    "665", -- variable is never set
    "666", -- variable is set but never accessed
    "667", -- variable is never accessed
    "668", -- variable is never set
    "669", -- variable is set but never accessed
    "671", -- variable is never accessed
    "672", -- variable is never set
    "673", -- variable is set but never accessed
    "674", -- variable is never accessed
    "675", -- variable is never set
    "676", -- variable is set but never accessed
    "677", -- variable is never accessed
    "678", -- variable is never set
    "679", -- variable is set but never accessed
    "681", -- variable is never accessed
    "682", -- variable is never set
    "683", -- variable is set but never accessed
    "684", -- variable is never accessed
    "685", -- variable is never set
    "686", -- variable is set but never accessed
    "687", -- variable is never accessed
    "688", -- variable is never set
    "689", -- variable is set but never accessed
    "691", -- variable is never accessed
    "692", -- variable is never set
    "693", -- variable is set but never accessed
    "694", -- variable is never accessed
    "695", -- variable is never set
    "696", -- variable is set but never accessed
    "697", -- variable is never accessed
    "698", -- variable is never set
    "699", -- variable is set but never accessed
    "711", -- variable is never accessed
    "712", -- variable is never set
    "713", -- variable is set but never accessed
    "714", -- variable is never accessed
    "715", -- variable is never set
    "716", -- variable is set but never accessed
    "717", -- variable is never accessed
    "718", -- variable is never set
    "719", -- variable is set but never accessed
    "721", -- variable is never accessed
    "722", -- variable is never set
    "723", -- variable is set but never accessed
    "724", -- variable is never accessed
    "725", -- variable is never set
    "726", -- variable is set but never accessed
    "727", -- variable is never accessed
    "728", -- variable is never set
    "729", -- variable is set but never accessed
    "731", -- variable is never accessed
    "732", -- variable is never set
    "733", -- variable is set but never accessed
    "734", -- variable is never accessed
    "735", -- variable is never set
    "736", -- variable is set but never accessed
    "737", -- variable is never accessed
    "738", -- variable is never set
    "739", -- variable is set but never accessed
    "741", -- variable is never accessed
    "742", -- variable is never set
    "743", -- variable is set but never accessed
    "744", -- variable is never accessed
    "745", -- variable is never set
    "746", -- variable is set but never accessed
    "747", -- variable is never accessed
    "748", -- variable is never set
    "749", -- variable is set but never accessed
    "751", -- variable is never accessed
    "752", -- variable is never set
    "753", -- variable is set but never accessed
    "754", -- variable is never accessed
    "755", -- variable is never set
    "756", -- variable is set but never accessed
    "757", -- variable is never accessed
    "758", -- variable is never set
    "759", -- variable is set but never accessed
    "761", -- variable is never accessed
    "762", -- variable is never set
    "763", -- variable is set but never accessed
    "764", -- variable is never accessed
    "765", -- variable is never set
    "766", -- variable is set but never accessed
    "767", -- variable is never accessed
    "768", -- variable is never set
    "769", -- variable is set but never accessed
    "771", -- variable is never accessed
    "772", -- variable is never set
    "773", -- variable is set but never accessed
    "774", -- variable is never accessed
    "775", -- variable is never set
    "776", -- variable is set but never accessed
    "777", -- variable is never accessed
    "778", -- variable is never set
    "779", -- variable is set but never accessed
    "781", -- variable is never accessed
    "782", -- variable is never set
    "783", -- variable is set but never accessed
    "784", -- variable is never accessed
    "785", -- variable is never set
    "786", -- variable is set but never accessed
    "787", -- variable is never accessed
    "788", -- variable is never set
    "789", -- variable is set but never accessed
    "791", -- variable is never accessed
    "792", -- variable is never set
    "793", -- variable is set but never accessed
    "794", -- variable is never accessed
    "795", -- variable is never set
    "796", -- variable is set but never accessed
    "797", -- variable is never accessed
    "798", -- variable is never set
    "799", -- variable is set but never accessed
    "811", -- variable is never accessed
    "812", -- variable is never set
    "813", -- variable is set but never accessed
    "814", -- variable is never accessed
    "815", -- variable is never set
    "816", -- variable is set but never accessed
    "817", -- variable is never accessed
    "818", -- variable is never set
    "819", -- variable is set but never accessed
    "821", -- variable is never accessed
    "822", -- variable is never set
    "823", -- variable is set but never accessed
    "824", -- variable is never accessed
    "825", -- variable is never set
    "826", -- variable is set but never accessed
    "827", -- variable is never accessed
    "828", -- variable is never set
    "829", -- variable is set but never accessed
    "831", -- variable is never accessed
    "832", -- variable is never set
    "833", -- variable is set but never accessed
    "834", -- variable is never accessed
    "835", -- variable is never set
    "836", -- variable is set but never accessed
    "837", -- variable is never accessed
    "838", -- variable is never set
    "839", -- variable is set but never accessed
    "841", -- variable is never accessed
    "842", -- variable is never set
    "843", -- variable is set but never accessed
    "844", -- variable is never accessed
    "845", -- variable is never set
    "846", -- variable is set but never accessed
    "847", -- variable is never accessed
    "848", -- variable is never set
    "849", -- variable is set but never accessed
    "851", -- variable is never accessed
    "852", -- variable is never set
    "853", -- variable is set but never accessed
    "854", -- variable is never accessed
    "855", -- variable is never set
    "856", -- variable is set but never accessed
    "857", -- variable is never accessed
    "858", -- variable is never set
    "859", -- variable is set but never accessed
    "861", -- variable is never accessed
    "862", -- variable is never set
    "863", -- variable is set but never accessed
    "864", -- variable is never accessed
    "865", -- variable is never set
    "866", -- variable is set but never accessed
    "867", -- variable is never accessed
    "868", -- variable is never set
    "869", -- variable is set but never accessed
    "871", -- variable is never accessed
    "872", -- variable is never set
    "873", -- variable is set but never accessed
    "874", -- variable is never accessed
    "875", -- variable is never set
    "876", -- variable is set but never accessed
    "877", -- variable is never accessed
    "878", -- variable is never set
    "879", -- variable is set but never accessed
    "881", -- variable is never accessed
    "882", -- variable is never set
    "883", -- variable is set but never accessed
    "884", -- variable is never accessed
    "885", -- variable is never set
    "886", -- variable is set but never accessed
    "887", -- variable is never accessed
    "888", -- variable is never set
    "889", -- variable is set but never accessed
    "891", -- variable is never accessed
    "892", -- variable is never set
    "893", -- variable is set but never accessed
    "894", -- variable is never accessed
    "895", -- variable is never set
    "896", -- variable is set but never accessed
    "897", -- variable is never accessed
    "898", -- variable is never set
    "899", -- variable is set but never accessed
    "911", -- variable is never accessed
    "912", -- variable is never set
    "913", -- variable is set but never accessed
    "914", -- variable is never accessed
    "915", -- variable is never set
    "916", -- variable is set but never accessed
    "917", -- variable is never accessed
    "918", -- variable is never set
    "919", -- variable is set but never accessed
    "921", -- variable is never accessed
    "922", -- variable is never set
    "923", -- variable is set but never accessed
    "924", -- variable is never accessed
    "925", -- variable is never set
    "926", -- variable is set but never accessed
    "927", -- variable is never accessed
    "928", -- variable is never set
    "929", -- variable is set but never accessed
    "931", -- variable is never accessed
    "932", -- variable is never set
    "933", -- variable is set but never accessed
    "934", -- variable is never accessed
    "935", -- variable is never set
    "936", -- variable is set but never accessed
    "937", -- variable is never accessed
    "938", -- variable is never set
    "939", -- variable is set but never accessed
    "941", -- variable is never accessed
    "942", -- variable is never set
    "943", -- variable is set but never accessed
    "944", -- variable is never accessed
    "945", -- variable is never set
    "946", -- variable is set but never accessed
    "947", -- variable is never accessed
    "948", -- variable is never set
    "949", -- variable is set but never accessed
    "951", -- variable is never accessed
    "952", -- variable is never set
    "953", -- variable is set but never accessed
    "954", -- variable is never accessed
    "955", -- variable is never set
    "956", -- variable is set but never accessed
    "957", -- variable is never accessed
    "958", -- variable is never set
    "959", -- variable is set but never accessed
    "961", -- variable is never accessed
    "962", -- variable is never set
    "963", -- variable is set but never accessed
    "964", -- variable is never accessed
    "965", -- variable is never set
    "966", -- variable is set but never accessed
    "967", -- variable is never accessed
    "968", -- variable is never set
    "969", -- variable is set but never accessed
    "971", -- variable is never accessed
    "972", -- variable is never set
    "973", -- variable is set but never accessed
    "974", -- variable is never accessed
    "975", -- variable is never set
    "976", -- variable is set but never accessed
    "977", -- variable is never accessed
    "978", -- variable is never set
    "979", -- variable is set but never accessed
    "981", -- variable is never accessed
    "982", -- variable is never set
    "983", -- variable is set but never accessed
    "984", -- variable is never accessed
    "985", -- variable is never set
    "986", -- variable is set but never accessed
    "987", -- variable is never accessed
    "988", -- variable is never set
    "989", -- variable is set but never accessed
    "991", -- variable is never accessed
    "992", -- variable is never set
    "993", -- variable is set but never accessed
    "994", -- variable is never accessed
    "995", -- variable is never set
    "996", -- variable is set but never accessed
    "997", -- variable is never accessed
    "998", -- variable is never set
    "999"  -- variable is set but never accessed
}
