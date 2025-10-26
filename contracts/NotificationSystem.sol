// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NotificationSystem
 * @dev A contract for managing push notifications and alerts
 * @author Swift v2 Team
 */
contract NotificationSystem is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // Events
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

    // Structs
    struct Notification {
        uint256 id;
        address sender;
        address recipient;
        string title;
        string message;
        string notificationType;
        uint256 timestamp;
        bool isRead;
        bool isDeleted;
        mapping(address => bool) readBy;
    }

    struct UserPreferences {
        bool messageNotifications;
        bool batchNotifications;
        bool transactionNotifications;
        bool systemNotifications;
        bool marketingNotifications;
        uint256 lastUpdated;
    }

    // State variables
    Counters.Counter private _notificationIdCounter;
    
    mapping(uint256 => Notification) public notifications;
    mapping(address => uint256[]) public userNotifications;
    mapping(address => UserPreferences) public userPreferences;
    mapping(address => bool) public authorizedContracts;
    mapping(string => bool) public supportedNotificationTypes;

    // Constants
    uint256 public constant MAX_TITLE_LENGTH = 100;
    uint256 public constant MAX_MESSAGE_LENGTH = 500;
    uint256 public constant NOTIFICATION_FEE = 0.000003 ether; // ~$0.009 at $3000 ETH

    // Modifiers
    modifier onlyAuthorized() {
        require(
            authorizedContracts[msg.sender] || msg.sender == owner(),
            "Not authorized to send notifications"
        );
        _;
    }

    modifier validNotification(string memory _title, string memory _message) {
        require(bytes(_title).length <= MAX_TITLE_LENGTH, "Title too long");
        require(bytes(_message).length <= MAX_MESSAGE_LENGTH, "Message too long");
        require(bytes(_title).length > 0, "Title required");
        require(bytes(_message).length > 0, "Message required");
        _;
    }

    modifier notificationExists(uint256 _notificationId) {
        require(_notificationId > 0 && _notificationId <= _notificationIdCounter.current(), "Notification does not exist");
        _;
    }

    constructor() {
        _notificationIdCounter.increment();
        
        // Initialize supported notification types
        supportedNotificationTypes["message"] = true;
        supportedNotificationTypes["batch_message"] = true;
        supportedNotificationTypes["transaction"] = true;
        supportedNotificationTypes["system"] = true;
        supportedNotificationTypes["marketing"] = true;
    }

    /**
     * @dev Send a notification
     * @param _recipient Address of the recipient
     * @param _title Notification title
     * @param _message Notification message
     * @param _notificationType Type of notification
     * @return notificationId ID of the sent notification
     */
    function sendNotification(
        address _recipient,
        string memory _title,
        string memory _message,
        string memory _notificationType
    ) 
        external 
        payable 
        nonReentrant 
        onlyAuthorized 
        validNotification(_title, _message)
        returns (uint256 notificationId) 
    {
        require(msg.value >= NOTIFICATION_FEE, "Insufficient notification fee");
        require(supportedNotificationTypes[_notificationType], "Unsupported notification type");
        require(_recipient != address(0), "Invalid recipient");

        // Check user preferences
        UserPreferences storage preferences = userPreferences[_recipient];
        if (preferences.lastUpdated > 0) {
            if (keccak256(bytes(_notificationType)) == keccak256("message") && !preferences.messageNotifications) {
                return 0; // User has disabled message notifications
            }
            if (keccak256(bytes(_notificationType)) == keccak256("batch_message") && !preferences.batchNotifications) {
                return 0; // User has disabled batch notifications
            }
            if (keccak256(bytes(_notificationType)) == keccak256("transaction") && !preferences.transactionNotifications) {
                return 0; // User has disabled transaction notifications
            }
            if (keccak256(bytes(_notificationType)) == keccak256("system") && !preferences.systemNotifications) {
                return 0; // User has disabled system notifications
            }
            if (keccak256(bytes(_notificationType)) == keccak256("marketing") && !preferences.marketingNotifications) {
                return 0; // User has disabled marketing notifications
            }
        }

        notificationId = _notificationIdCounter.current();
        _notificationIdCounter.increment();

        Notification storage notification = notifications[notificationId];
        notification.id = notificationId;
        notification.sender = msg.sender;
        notification.recipient = _recipient;
        notification.title = _title;
        notification.message = _message;
        notification.notificationType = _notificationType;
        notification.timestamp = block.timestamp;
        notification.isRead = false;
        notification.isDeleted = false;

        userNotifications[_recipient].push(notificationId);

        emit NotificationSent(notificationId, _recipient, _title, _message, _notificationType, block.timestamp);
    }

    /**
     * @dev Mark notification as read
     * @param _notificationId ID of the notification
     */
    function markAsRead(uint256 _notificationId) 
        external 
        notificationExists(_notificationId)
    {
        Notification storage notification = notifications[_notificationId];
        require(notification.recipient == msg.sender, "Not the recipient");
        require(!notification.isDeleted, "Notification deleted");

        if (!notification.isRead) {
            notification.isRead = true;
            notification.readBy[msg.sender] = true;
            emit NotificationRead(_notificationId, msg.sender);
        }
    }

    /**
     * @dev Delete a notification
     * @param _notificationId ID of the notification
     */
    function deleteNotification(uint256 _notificationId) 
        external 
        notificationExists(_notificationId)
    {
        Notification storage notification = notifications[_notificationId];
        require(notification.recipient == msg.sender, "Not the recipient");
        require(!notification.isDeleted, "Notification already deleted");

        notification.isDeleted = true;
        emit NotificationDeleted(_notificationId, msg.sender);
    }

    /**
     * @dev Update user notification preferences
     * @param _messageNotifications Enable/disable message notifications
     * @param _batchNotifications Enable/disable batch notifications
     * @param _transactionNotifications Enable/disable transaction notifications
     * @param _systemNotifications Enable/disable system notifications
     * @param _marketingNotifications Enable/disable marketing notifications
     */
    function updateNotificationPreferences(
        bool _messageNotifications,
        bool _batchNotifications,
        bool _transactionNotifications,
        bool _systemNotifications,
        bool _marketingNotifications
    ) external {
        UserPreferences storage preferences = userPreferences[msg.sender];
        preferences.messageNotifications = _messageNotifications;
        preferences.batchNotifications = _batchNotifications;
        preferences.transactionNotifications = _transactionNotifications;
        preferences.systemNotifications = _systemNotifications;
        preferences.marketingNotifications = _marketingNotifications;
        preferences.lastUpdated = block.timestamp;

        emit SubscriptionUpdated(msg.sender, "message", _messageNotifications);
        emit SubscriptionUpdated(msg.sender, "batch_message", _batchNotifications);
        emit SubscriptionUpdated(msg.sender, "transaction", _transactionNotifications);
        emit SubscriptionUpdated(msg.sender, "system", _systemNotifications);
        emit SubscriptionUpdated(msg.sender, "marketing", _marketingNotifications);
    }

    /**
     * @dev Get user's notifications
     * @param _user Address of the user
     * @param _offset Starting index
     * @param _limit Number of notifications to return
     * @return Array of notification IDs
     */
    function getUserNotifications(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        uint256[] memory userNotificationIds = userNotifications[_user];
        uint256 length = userNotificationIds.length;
        
        if (_offset >= length) {
            return new uint256[](0);
        }

        uint256 end = _offset + _limit;
        if (end > length) {
            end = length;
        }

        uint256[] memory result = new uint256[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            result[i - _offset] = userNotificationIds[i];
        }

        return result;
    }

    /**
     * @dev Get notification details
     * @param _notificationId ID of the notification
     * @return Notification details
     */
    function getNotification(uint256 _notificationId) 
        external 
        view 
        notificationExists(_notificationId)
        returns (
            uint256 id,
            address sender,
            address recipient,
            string memory title,
            string memory message,
            string memory notificationType,
            uint256 timestamp,
            bool isRead,
            bool isDeleted
        ) 
    {
        Notification storage notification = notifications[_notificationId];
        return (
            notification.id,
            notification.sender,
            notification.recipient,
            notification.title,
            notification.message,
            notification.notificationType,
            notification.timestamp,
            notification.isRead,
            notification.isDeleted
        );
    }

    /**
     * @dev Get user's unread notification count
     * @param _user Address of the user
     * @return Number of unread notifications
     */
    function getUnreadCount(address _user) external view returns (uint256) {
        uint256[] memory userNotificationIds = userNotifications[_user];
        uint256 unreadCount = 0;

        for (uint256 i = 0; i < userNotificationIds.length; i++) {
            uint256 notificationId = userNotificationIds[i];
            Notification storage notification = notifications[notificationId];
            if (!notification.isRead && !notification.isDeleted) {
                unreadCount++;
            }
        }

        return unreadCount;
    }

    /**
     * @dev Get user's notification preferences
     * @param _user Address of the user
     * @return User preferences
     */
    function getUserPreferences(address _user) 
        external 
        view 
        returns (
            bool messageNotifications,
            bool batchNotifications,
            bool transactionNotifications,
            bool systemNotifications,
            bool marketingNotifications,
            uint256 lastUpdated
        ) 
    {
        UserPreferences storage preferences = userPreferences[_user];
        return (
            preferences.messageNotifications,
            preferences.batchNotifications,
            preferences.transactionNotifications,
            preferences.systemNotifications,
            preferences.marketingNotifications,
            preferences.lastUpdated
        );
    }

    /**
     * @dev Add supported notification type
     * @param _notificationType Type of notification to add
     */
    function addSupportedNotificationType(string memory _notificationType) external onlyOwner {
        supportedNotificationTypes[_notificationType] = true;
    }

    /**
     * @dev Remove supported notification type
     * @param _notificationType Type of notification to remove
     */
    function removeSupportedNotificationType(string memory _notificationType) external onlyOwner {
        supportedNotificationTypes[_notificationType] = false;
    }

    /**
     * @dev Authorize a contract to send notifications
     * @param _contract Address of the contract
     */
    function authorizeContract(address _contract) external onlyOwner {
        authorizedContracts[_contract] = true;
    }

    /**
     * @dev Revoke contract authorization
     * @param _contract Address of the contract
     */
    function revokeContractAuthorization(address _contract) external onlyOwner {
        authorizedContracts[_contract] = false;
    }

    /**
     * @dev Get total notification count
     * @return Total number of notifications
     */
    function getTotalNotificationCount() external view returns (uint256) {
        return _notificationIdCounter.current() - 1;
    }

    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
