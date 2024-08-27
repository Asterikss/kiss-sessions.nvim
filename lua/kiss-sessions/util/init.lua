local Path = require("plenary.path")
local Job = require("plenary.job")

local M = {}

M.get_sessions = function (session_dir)
    local sessions = {}

    Job:new({
        command = 'ls',
        args = {'-lt', session_dir},
        on_stdout = function(_, line)
            -- Skip the first line ("total X")
            if not line:match("^total") then
                -- Extract the file name from the line
                local filename = line:match("%s([^%s]+)$")
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

M.session_exists = function (path)
    return Path:new(path):exists()
end

M.remove_session_by_name = function (sessions, target_session_name)
    for i, session_name in ipairs(sessions) do
        if session_name == target_session_name then
            table.remove(sessions, i)
            return sessions
        end
    end
    return sessions
end

return M
