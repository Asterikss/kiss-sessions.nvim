local core = require("kiss-sessions.core")

return {
    SaveSession = core.SaveSession,
    LoadSession = core.LoadSession,
    LoadDefatulSession = core.LoadDefatulSession,
    SaveDefaultSessionAndQuit = core.SaveDefaultSessionAndQuit,
    setup = core.setup,
}
