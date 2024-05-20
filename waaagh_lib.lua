-- Example: IzUsableAction("Ability_Warrior_Revenge")
-- To get slot texture can do :

-- for id = 1,120 do
--     local texture = GetActionTexture(i)
--     if texture then
--         print(id .. texture)
--     end
-- end


function GetTextureID(name)
    for id = 1,120 do
        local texture = GetActionTexture(id)
        if texture and string.find(texture, name) then
            return id
        end
    end
end