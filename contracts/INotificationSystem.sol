// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title INotificationSystem
 * @dev Interface for the NotificationSystem contract
 */
interface INotificationSystem {
    event NotificationSent(
        uint256 indexed notificationId,
        address indexed recipient,
        string title,
        string message,
        string notificationType,
        uint256 timestamp
    );

    event NotificationRead(
        uint256 indexed notificationId,
        address indexed reader
    );

    event NotificationDeleted(
        uint256 indexed notificationId,
        address indexed deleter
    );

    event SubscriptionUpdated(
        address indexed user,
        string notificationType,
        bool isSubscribed
    );

    function sendNotification(
        address _recipient,
        string memory _title,
        string memory _message,
        string memory _notificationType
    ) external payable returns (uint256 notificationId);

    function markAsRead(uint256 _notificationId) external;

    function deleteNotification(uint256 _notificationId) external;

    function updateNotificationPreferences(
        bool _messageNotifications,
        bool _batchNotifications,
        bool _transactionNotifications,
        bool _systemNotifications,
        bool _marketingNotifications
    ) external;

    function getUnreadCount(address _user) external view returns (uint256);
}
