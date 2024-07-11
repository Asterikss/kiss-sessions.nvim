local M = {}

local session_dir

M.setup = function (opts)
    session_dir = opts.session_dir or "./.dev/.sessions"
end

return M
