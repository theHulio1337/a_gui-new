function createAlert(player, type, msg)
    triggerClientEvent(player, "createAlert", resourceRoot, type, msg)
end