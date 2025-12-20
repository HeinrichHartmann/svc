# Checkly Private Location Agent

This service runs a Checkly Private Location agent to monitor internal services.

## Setup

1. Create a Private Location in your Checkly account at https://app.checklyhq.com/private-locations
2. Copy the API key (starts with `pl_...`)
3. Save the API key to `~/box/secrets/checkly-agent.key`:
   ```bash
   echo "pl_your_api_key_here" > ~/box/secrets/checkly-agent.key
   ```
4. Start the agent:
   ```bash
   make start
   ```

## Usage

- Start: `make start`
- Stop: `make stop`
- Restart: `make restart`
- View logs: `make logs`
- Check status: `make status`

## Resources

The agent is configured with:
- CPU: 1-2 cores
- Memory: 2-4GB

## Documentation

- [Checkly Private Locations Overview](https://www.checklyhq.com/docs/platform/private-locations/overview/)
- [Agent Configuration](https://www.checklyhq.com/docs/platform/private-locations/agent-configuration/)
