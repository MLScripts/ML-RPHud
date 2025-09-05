-- ============================================================= --
--              © 2025 MLscripts. All Rights Reserved            --
--    Gebruik, verspreiding of wijziging alleen met toestemming. --
-- ============================================================= --

local function printMLBanner(resource)
    local lines = {
        "^3", 
        "^5███╗   ███╗██╗         ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗^0",
        "^5████╗ ████║██║         ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝^0",
        "^5██╔████╔██║██║         ███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗^0",
        "^5██║╚██╔╝██║██║         ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║^0",
        "^5██║ ╚═╝ ██║███████╗    ███████║╚██████╗██║  ██║██║██║        ██║   ███████║^0",
        "^5╚═╝     ╚═╝╚══════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝^0",
        "^3", 
        ("^2  © %s MLscripts. Alle rechten voorbehouden.^0"):format(os.date("%Y")),
        ("^2  Resource:^0 %s   ^2Gestart op:^0 %s"):format(resource or "unknown", os.date("%Y-%m-%d %H:%M:%S")),
        "^5  GitHub:^0 https://github.com/MLScripts",
        "^3"
    }

    print("")
    for _, l in ipairs(lines) do
        print(l)
    end
    print("")
end

AddEventHandler("onResourceStart", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(200) 
        printMLBanner(resName)
    end)
end)
