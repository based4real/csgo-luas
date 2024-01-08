local cmds = {}
cmds = {
    ["cfg"] = {
        help = function(addition)
            addition = addition or ""
            print(addition .. "cfg:")
            print(addition .. "     - export: export the current configuration to clipboard")
            print(addition .. "     - import: import a configuration from clipboard")
        end,
        ["export"] = function()
            -- export config to clipboard
            print("Exporting current configuration to clipboard")
        end,
        ["import"] = function()
            -- import config from clipboard
            print("Importing configuration from clipboard")
        end
    },
    ["get"] = {
        help = function(addition)
            addition = addition or ""
            print(addition .. "get:")
            print(addition .. "     - aa: get anti-aim settings")
        end,
        ["aa"] = {
            help = function(addition)
                addition = addition or ""
                print(addition .. "get aa:")
                print(addition .. "    - details: gets the current details of your anti-aim")
                print(addition .. "    - log: gets current log for all logged entities")
            end,
        },
    },
    ["set"] = {
        help = function(addition)
            addition = addition or ""
            print(addition .. "set:")
            print(addition .. "     - aa: set anti-aim settings")
        end,
        ["aa"] = {
            help = function(addition)
                addition = addition or ""
                print(addition .. "set aa:")
                print(addition .. "    - yaw: set yaw")
                print(addition .. "    - desync: set desync")
            end,
            ["yaw"] = function(extraInfo)
                -- set the yaw menu element or something
                -- yaw_menu_element:Set(extraInfo) or whatever
                print(":c")
            end,
            ["desync"] = function(extraInfo)
                -- set the yaw menu element or something
                -- yaw_menu_element:Set(extraInfo) or whatever
                print("desync correct: " .. extraInfo)
            end,
        },
    },
    ["help"] = function ()
        -- print all commands and their sub commands
        for k, v in pairs(cmds) do
            if k ~= "help" then
                if type(v) == "table" then
                    v.help("\t")
                    for k2, v2 in pairs(v) do
                        if type(v2) == "table" then
                            v2.help("\t\t")
                        end
                    end
                end
            end
        end
    end
}
cmds.help()

local function splitString(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- fetch input from console
--local input = io.read()

local function handleCommand(input)
    -- our input could be "cfg export <file name>"
    -- split input string at " "
    -- cmd is the main command, for example "cfg"
    -- subCmd is the possible subCommand, for example "export"
    -- cmdInfo is the possible extra information that a command might need, for example "<file name> or <number> for menu settings"
    
    -- extract cmd and subCmd from the input and save the rest in a table
    local cmdInfo = splitString(input, " ")
    cmd = cmdInfo[1]
    subCmd = cmdInfo[2]

    if cmdInfo[3] ~= nil then
        subSubCmd = cmdInfo[3]
        subSubValueCmd = cmdInfo[4]
        table.remove(cmdInfo, 1) 
        table.remove(cmdInfo, 1) 
    end

    -- remove cmd and subCmd from cmdInfo and save the rest into cmdInfo
    table.remove(cmdInfo, 1) 
    table.remove(cmdInfo, 1)

    -- check if our command is valid
    if cmds[cmd] then
        -- if our command is valid, check if we have a sub command, by checking if its a table
        if type(cmds[cmd]) == "table" then
            -- check if the provided sub command exists for our current command
            if cmds[cmd][subCmd] then
                -- if so, call the command callback with the parameter "cmdInfo"
                if subSubCmd == nil or subSubValueCmd == nil then
                    if type(cmds[cmd][subCmd]) == "table" then
                        cmds[cmd][subCmd].help()
                    else
                        cmds[cmd][subCmd](cmdInfo)
                    end
                else
                    if subSubCmd ~= nil then
                        print(cmdInfo[1])
                        cmds[cmd][subCmd][subSubCmd](cmdInfo)
                    end
                end
            else
                -- if the provided sub command doesnt exist or wasn't provided, call the help function
                cmds[cmd].help("")
            end
        else
            -- our command wasn't a table, meaning it doesnt contain any sub commands, so call the command callback directly
            cmds[cmd]()
        end
    else
        -- our command was not valid, so let the user know
        print("Command not found")
    end
end

--handleCommand(input)


client.set_event_callback("console_input", function(input)
        handleCommand(input)


end)