-- Stop walking immediately
player.walking_state = {walking = false}
rcon.print(string.format("STOPPED at (%.1f, %.1f)", player.position.x, player.position.y))
