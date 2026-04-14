local jabby = require("@game/ReplicatedStorage/Packages/jabby")

local scheduler = jabby.scheduler.create()

jabby.set_check_function(function(player: Player) 
	return true
end)

jabby.register({
	applet = jabby.applets.scheduler,
	name = "Server Scheduler",
	configuration = {
		scheduler = scheduler
	}
} :: any)

return scheduler
