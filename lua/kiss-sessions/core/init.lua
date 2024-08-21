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

local _find_git_root_or_cwd = function ()
    -- Use the current buffer's path as the starting point for the git search
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_dir
    local cwd = vim.fn.getcwd()

    if current_file == "" then
        current_dir = cwd
    else
        -- When opening a dir with neovim (nvim .), the code in else block would strip the last
        -- directory intead of the name of the file. This causes errors, so there is a check.
        if vim.fn.isdirectory(current_file) == 1 then
            -- current_dir = current_file
            -- this does not work for example with oil
            -- "oil:///home/..." will not work with the git command
            -- this does not matter if _find_git_root() is executed once on startup,
            -- but if it would be executed before e.g. saving a session then that
            -- could fail given that the user navigated to a different project from
            -- within neovim. Could just strip the prefix. For now it does not matter.
            current_dir = cwd
        else
            -- Extract the directory from the current file's path
            current_dir = vim.fn.fnamemodify(current_file, ":h")
        end
    end
    -- Find the Git root directory from the current file's path
    local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
      return cwd
    end
    return git_root
end

M.setup = function (opts)
    session_dir = _find_git_root_or_cwd() .. (opts.session_dir or "/.dev/.sessions/")
    default_session_name = opts.default_session_name or "Session"
    vim.api.nvim_create_user_command(
        "LoadDefatulSession",
        LoadDefatulSession,
        {desc = "Load default session"}
    )
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
    vim.uv.fs_rename(old_path, new_path)
    print("Session " .. session_name .. " renamed to " .. new_name)

    if current_session == session_name then
        current_session = new_name
    end
end

local _display_sessions = function (sessions, title, cr_action)
    local sessions_picker = function(opts)
        opts = opts or {}
        pickers.new(opts, {
            prompt_title = "Ξ " .. title .. " Ξ",
            finder = finders.new_table {
                results = sessions,
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                map({"i", "n"}, "<CR>", function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)

                    local selection_value = selection.value
                    if selection.index == 1 then
                        selection_value = string.gsub(selection_value, current_session_pattern, "")
                    end

                    cr_action(selection_value)
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
                    vim.uv.fs_unlink(p)
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
        table.insert(sessions, current_session .. current_session_banner)
    end

    _display_sessions(sessions, "Sessions", _load_session)
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
        table.insert(sessions, 1, new_session_banner)
        table.insert(sessions, 1, current_session .. current_session_banner)
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

            vim.cmd("mks! " .. path)

            current_session = new_session_name

            print("Session " .. session_option .. "has been created successfully")
        else
            -- already existing session choosen
            vim.cmd("mks! " .. session_dir .. session_option .. ".vim")
            print("Session " .. session_option .. "has been overridden successfully")
            current_session = session_option
        end
    end

    _display_sessions(sessions, "Sessions (Save)", save_session)
end

M.SaveDefaultSessionAndQuit = function ()
    util.ensure_session_dir_exists(session_dir)

    local path = session_dir .. default_session_name .. ".vim"

    vim.cmd("wa")
    vim.cmd("mks! " .. path)
    vim.cmd("qa")
end

return M
