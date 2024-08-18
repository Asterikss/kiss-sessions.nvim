local util = require("kiss-sessions.util")

local M = {}

local session_dir
local loadFrom = ""

M.setup = function (opts)
    session_dir = opts.session_dir or "./.dev/.sessions"
end

M.SaveSession = function()
    if loadFrom ~= "" then
        local p = session_dir .. loadFrom .. ".vim"
        vim.cmd("mksession! " .. p)
    else
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
