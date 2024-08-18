local Path = require("plenary.path")
local Job = require("plenary.Job")

local M = {}

M.get_sessions = function (session_dir)
    local sessions = {}

    Job:new({
        command = 'ls',
        args = {'-lt', session_dir},
        on_stdout = function(_, line)
            print(line)
            -- Skip the first line ("total X")
            if not line:match("^total") then
                -- Extract the file name from the line
                local filename = line:match("%s([^%s]+)$"):sub(1, -5)
            if filename then
                    table.insert(sessions, filename)
                end
            end
        end,
        }):sync()
    return sessions
end

M.ensure_session_dir_exists = function (path)
    if not Path:new(path):exists() then
        Path:new(path):mkdir({ parents = true })
    end
end

M.session_exists = function(path)
    return Path:new(path):exists()
end

return M
