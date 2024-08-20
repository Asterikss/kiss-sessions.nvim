local util = require("kiss-sessions.util")

local M = {}

local session_dir
local current_session

local new_session_banner = "* New Session *"

M.setup = function (opts)
    session_dir = opts.session_dir or "./.dev/.sessions/"
end

local _load_session = function(session_name)
    local path = session_dir .. session_name .. ".vim"
    if not util.session_exists(path) then
        print("Session does not exist")
        return
    end
    vim.cmd("source " .. path)
    current_session = session_name
end

local _rename_session = function(session_name)
    local new_name = vim.fn.input("New name (" .. session_name .. "): ", session_name)
    if new_name == "" then
        print("Session name cannot be empty")
        return
    end

    local new_path = session_dir .. new_name .. ".vim"
    if util.session_exists(new_path) then
        print("Session name already exists")
        return
    end

    local old_path = session_dir .. session_name .. ".vim"
    vim.loop.fs_rename(old_path, new_path) -- vim.uv
    print("Session " .. session_name .. " renamed to " .. new_name)

    if current_session == session_name then
        current_session = new_name
    end
end

        local session_name = vim.fn.input("Session name: ")
        if session_name == "" then
            print("Session name cannot be empty")
            return
        end

        util.create_dir(session_dir)

        local p = session_dir .. session_name .. ".vim"

        local session_exists = util.session_exists(p)

        if session_exists then
            print("Session name already exists")
        end

        vim.cmd("mksession! " .. p)

        loadFrom = session_name

        vim.cmd([[echo "\n"]])
    end

    vim.cmd([[echo ""]])
    print("Session " .. loadFrom .. " saved")
end

return M
