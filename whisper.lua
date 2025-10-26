SLASH_WHISPERW1 = "/ww"
SLASH_WHISPERW2 = "/whisperw"

SlashCmdList["WHISPERW"] = function(msg)
    local _, _, target, text = string.find(msg, "^(%S+)%s+(.+)")
    if target and text then
        SendChatMessage(text, "WHISPER", nil, target)
    else
        print("Usage: /ww <player> <message>")
    end
end