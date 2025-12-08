# Architecture

## Overview
The Notification System is a smart contract designed to manage notifications on the blockchain.

## Components

### NotificationSystem.sol
This is the main contract. It handles:
- Sending notifications.
- Managing user preferences.
- Access control for notification senders.

## Data Structures
- **Notification**: Struct containing message details, timestamp, and sender.
- **Preferences**: Mapping of user addresses to their notification settings.

## Flow
1. Users register their preferences.
2. Authorized senders push notifications to users.
3. Users can retrieve their notifications.
