local util = require("kiss-sessions.util")
local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

local session_dir
local current_session
local default_session_name

M.setup = function (opts)
    session_dir = opts.session_dir or "./.dev/.sessions/"
end
local new_session_banner = "Δ New Session Δ"
local current_session_banner = "      <- current session Δ"
local current_session_pattern = "%s*<%- current session Δ$"

local _load_session = function(session_name)
    local path = session_dir .. session_name .. ".vim"
    if not util.session_exists(path) then
        print("Session " .. session_name .. " does not exist")
        return
    end
    vim.cmd("source " .. path)
    current_session = session_name
end

local LoadDefatulSession = function ()
    if not util.session_exists(session_dir .. default_session_name .. ".vim") then
        print("Default session '" .. default_session_name .. "' does not exist")
    else
        _load_session(default_session_name)
        current_session = default_session_name
    end
end
M.LoadDefatulSession = LoadDefatulSession

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

local _display_sessions = function (sessions, cr_action)
    local sessions_picker = function(opts)
        opts = opts or {}
        pickers.new(opts, {
            prompt_title = "Ξ Sessions Ξ",
            finder = finders.new_table {
                results = sessions,
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                map({"i", "n"}, "<CR>", function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    cr_action(selection.value)
                end)
                map("i", "<C-d>", function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)

                    local confirm = vim.fn.input("Delete " .. selection.value .. "? (y/N): ")
                    if confirm ~= "y" then
                        print("Deletion canceled")
                        return
                    end

                    if current_session == selection.value then
                        current_session = nil
                    end
                    local p = session_dir .. selection.value .. ".vim"
                    vim.loop.fs_unlink(p) -- vim.uv
                    print("Session deleted")
                end)
                map("i", "<C-r>", function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    _rename_session(selection.value)
                end)
                return true
            end,
        }):find()
    end
    sessions_picker(require("telescope.themes").get_dropdown({}))
end

M.LoadSession = function ()
    local sessions = util.get_sessions(session_dir)

    if current_session then
        for i, session_name in ipairs(sessions) do
            if session_name == current_session then
                table.remove(sessions, i)
                break
            end
        end
        table.insert(sessions, current_session .. "    * current session *")
    end

    _display_sessions(sessions, _load_session)
end

M.SaveSession = function ()
    local sessions = util.get_sessions(session_dir)

    if current_session then
        for i, session_name in ipairs(sessions) do
            if session_name == current_session then
                table.remove(sessions, i)
                break
            end
        end
        table.insert(sessions, 1, current_session .. "   <- save on top of current session")
    else
        table.insert(sessions, 1, new_session_banner)
    end

    local save_session = function (session_option)
        if session_option == new_session_banner then
            local new_session_name = vim.fn.input("Session name: ")
            if new_session_name == "" then
                print("Session name cannot be empty")
                return
            end

            util.ensure_session_dir_exists(session_dir)

            local path = session_dir .. new_session_name .. ".vim"

            if util.session_exists(path) then
                print("Session name already exists")
                return
            end

            vim.cmd("mksession! " .. path)

            current_session = new_session_name

            print("Session " .. session_option .. "has been created successfully")
        else
            -- already existing session choosen
            vim.cmd("mksession! " .. session_dir .. session_option .. ".vim")
            print("Session " .. session_option .. "has been overridden successfully")
        end
    end

    _display_sessions(sessions, save_session)
end

return M
