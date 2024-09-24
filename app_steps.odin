package tyr

// called once at the start of the application before everything else
init_step :: struct {
	using step: app_step,
}

// called once at the start of the application
start_step :: struct {
	using step: app_step,
}

// called every frame
update_step :: struct {
	using step: app_step,
}

// called on a fixed time interval, regardless of the frame rate
fixed_update_step :: struct {
	using step: app_step,
}

// called once when the application is done
stop_step :: struct {
	using step: app_step,
}

// called once when the application is done after everything else
deinit_step :: struct {
	using step: app_step,
}