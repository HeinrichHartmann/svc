URL=
include /svc/lib/include.mk

metrics:
	$(info # HELP last_success Last time the cron job ran successfully)
	$(info # TYPE last_success gauge)
	@printf 'last_success{service="telegram_bot"} '; docker compose exec telegram_bot date -r /tmp/heartbeat +%s
