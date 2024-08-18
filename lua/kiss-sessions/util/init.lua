local Path = require("plenary.path")

local M = {}

M.create_dir = function(path)
    if not Path:new(path):exists() then
        Path:new(path):mkdir({ parents = true })
    end
end

M.session_exists = function(path)
    return Path:new(path):exists()
end

return M
