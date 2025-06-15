local core = require('kiss-sessions.core')

return {
  SaveSession = core.SaveSession,
  LoadSession = core.LoadSession,
  LoadDefaultSession = core.LoadDefaultSession,
  SaveDefaultSessionAndQuit = core.SaveDefaultSessionAndQuit,
  setup = core.setup,
}
