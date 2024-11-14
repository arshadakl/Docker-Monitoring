# Docker Container Crash Monitor 🚨

A simple but powerful bash script that monitors your Docker containers and sends Slack notifications when containers crash. Perfect for keeping tabs on your containers' health without constantly checking logs.

## What does it do? 🤔

Ever had a Docker container silently die on you? Yeah, me too. That's why I built this. It sits quietly in the background watching your containers, and the moment one crashes - BAM! - you get a Slack notification with all the important details:

- Container name
- Container ID
- Image used
- Exit code
- How long it ran
- Which host it was running on

## Setup Guide 🛠️

### 1. Get the files ready

First, let's get the monitoring script and service file where they need to be:

Create the monitor script:
```bash
# Create the script file
sudo nano /usr/local/bin/docker-monitor.sh

# Make it executable
sudo chmod +x /usr/local/bin/docker-monitor.sh
```

Create the service file:
```bash
sudo nano /etc/systemd/system/docker-monitor.service
```

Copy the contents from both files in this repo into these new files.

### 2. Set up your Slack webhook

1. Go to your Slack workspace
2. Create a new webhook (or use an existing one) at https://api.slack.com/apps
3. Copy the webhook URL
4. Replace the `SLACK_WEBHOOK_URL` in the script with your URL:
   ```bash
   sudo nano /usr/local/bin/docker-monitor.sh
   # Find and replace this line:
   SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
   ```

### 3. Start it up! 🚀

Time to get this baby running:

```bash
# Reload systemd to pick up the new service
sudo systemctl daemon-reload

# Enable it to start on boot (because who wants to do this manually?)
sudo systemctl enable docker-monitor

# Start it right now
sudo systemctl start docker-monitor
```

### 4. Check if it's working

Let's make sure everything's running smoothly:

```bash
# Check the service status
sudo systemctl status docker-monitor

# Take a peek at the logs
sudo journalctl -u docker-monitor -f
# or
sudo tail -f /var/log/docker-monitor.log
```

## Common Commands 🛠️

Here are some handy commands you might need:

```bash
# Stop the monitor
sudo systemctl stop docker-monitor

# Start it up again
sudo systemctl start docker-monitor

# Restart it (turn it off and on again, the universal fix!)
sudo systemctl restart docker-monitor

# Don't want it to start on boot?
sudo systemctl disable docker-monitor

# Check its current status
sudo systemctl status docker-monitor
```

## Troubleshooting 🔍

### Nothing's happening when containers crash

1. Check if the service is running:
   ```bash
   sudo systemctl status docker-monitor
   ```

2. Make sure your Slack webhook is correct:
   ```bash
   # Test the webhook directly
   curl -X POST -H 'Content-type: application/json' \
       --data '{"text":"Test message"}' \
       YOUR_WEBHOOK_URL
   ```

3. Check the logs:
   ```bash
   sudo journalctl -u docker-monitor -f
   ```

### Getting duplicate notifications

This shouldn't happen with the latest version, but if it does:
1. Stop the service
2. Clear the logs
3. Restart the service

```bash
sudo systemctl stop docker-monitor
sudo truncate -s 0 /var/log/docker-monitor.log
sudo systemctl start docker-monitor
```

## Files Location Map 🗺️

Just so you know where everything lives:

- Script: `/usr/local/bin/docker-monitor.sh`
- Service file: `/etc/systemd/system/docker-monitor.service`
- Log file: `/var/log/docker-monitor.log`

