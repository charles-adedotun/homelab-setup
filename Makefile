# Define variables
SCRIPT_DIR := $(shell pwd)
START_SCRIPT := $(SCRIPT_DIR)/scripts/start.sh
DEPLOY_SCRIPT := $(SCRIPT_DIR)/scripts/deploy.sh
STOP_SCRIPT := $(SCRIPT_DIR)/scripts/stop.sh
DNS_SCRIPT := $(SCRIPT_DIR)/scripts/dns.sh
MACVLAN_SCRIPT := $(SCRIPT_DIR)/scripts/macvlan.sh

.PHONY: help install start deploy stop uninstall macvlan dns

help:  ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install      Set up the environment and configure startup tasks"
	@echo "  start        Start all services"
	@echo "  deploy       Deploy Docker services"
	@echo "  stop         Stop all services"
	@echo "  uninstall    Remove the setup and configurations"
	@echo "  macvlan      Configure the macvlan interface"
	@echo "  dns          Configure DNS and restart systemd-resolved"

install: make_executable add_to_crontab initial_setup  ## Set up the environment and configure startup tasks

make_executable:  ## Make necessary scripts executable
	@chmod +x $(START_SCRIPT) $(DEPLOY_SCRIPT) $(STOP_SCRIPT) $(DNS_SCRIPT) $(MACVLAN_SCRIPT)
	@echo "All necessary scripts are now executable."

add_to_crontab:  ## Add the start script to crontab to run at reboot
	@(crontab -l 2>/dev/null; echo "@reboot $(START_SCRIPT)") | crontab -
	@echo "Startup script added to crontab."

initial_setup: dns macvlan deploy  ## Perform initial setup

start: dns macvlan deploy  ## Start all services
	@echo "All services started."

deploy:  ## Deploy Docker services
	@$(DEPLOY_SCRIPT)

stop:  ## Stop all services
	@$(STOP_SCRIPT)

uninstall: stop remove_from_crontab  ## Remove the setup and configurations

remove_from_crontab: make_executable ## Remove the startup script from crontab
	@(crontab -l | grep -v "@reboot $(START_SCRIPT)") | crontab -
	@echo "Startup script removed from crontab."

macvlan: make_executable ## Configure the macvlan interface
	@$(MACVLAN_SCRIPT)

dns: make_executable ## Configure DNS and restart systemd-resolved
	@$(DNS_SCRIPT)
