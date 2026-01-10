# CyberTabView - Segmented Tab Navigation

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberTabView Widget](#cybertabview-widget)
3. [CyberTab Model](#cybertab-model)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberTabView` là tab navigation widget với **iOS-style segmented control**, **lazy loading**, và **smooth animations**. Widget này cung cấp trải nghiệm tab navigation đẹp mắt và hiệu suất cao.

### Đặc Điểm Chính

- ✅ **iOS-Style Design**: Segmented pill-style tabs
- ✅ **Lazy Loading**: Load view khi cần thiết
- ✅ **Smooth Animation**: 268ms iOS-standard animation
- ✅ **Auto Scroll**: Tab bar tự động scroll đến active tab
- ✅ **Badge Support**: Notification badges trên tabs
- ✅ **Icon Support**: Icons cho mỗi tab
- ✅ **Keep Alive**: Optional view caching
- ✅ **Dual Mode**: View name hoặc child widget
- ✅ **Scrollable**: Support nhiều tabs với scroll

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberTabView Widget

### Constructor

```dart
const CyberTabView({
  super.key,
  required this.tabs,
  this.initialIndex = 0,
  this.backColorTab,
  this.textColorTab,
  this.selectBackColorTab,
  this.selectTextColorTab = Colors.black,
  this.tabBarHeight,
  this.keepAlive = false,
  this.onTabChanged,
  this.tabBorderRadius,
  this.tabSpacing = 8,
  this.tabBarMargin,
  this.isScrollable = true,
  this.animationDuration,
  this.animationCurve = Curves.easeInOut,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `tabs` | `List<CyberTab>` | Danh sách tabs | Required |
| `initialIndex` | `int` | Tab được chọn ban đầu | 0 |
| `backColorTab` | `Color?` | Màu nền tab bar | Color(0xFFE8F5E9) |
| `textColorTab` | `Color?` | Màu text tab không active | Color(0xFF2E7D32) |
| `selectBackColorTab` | `Color?` | Màu nền tab active | Colors.grey[200] |
| `selectTextColorTab` | `Color?` | Màu text tab active | Colors.black |
| `tabBarHeight` | `double?` | Chiều cao tab bar | null (auto) |
| `keepAlive` | `bool` | Cache views khi switch tabs | false |
| `onTabChanged` | `Function(int)?` | Callback khi đổi tab | null |
| `tabBorderRadius` | `BorderRadius?` | Bo góc tab bar | BorderRadius.circular(18) |
| `tabSpacing` | `double?` | Khoảng cách giữa tabs | 8 |
| `tabBarMargin` | `EdgeInsets?` | Margin của tab bar | EdgeInsets.symmetric(horizontal: 32, vertical: 16) |
| `isScrollable` | `bool` | Cho phép scroll tabs | true |
| `animationDuration` | `Duration?` | Thời gian animation | Duration(milliseconds: 268) |
| `animationCurve` | `Curve?` | Animation curve | Curves.easeInOut |

---

## CyberTab Model

### Constructor

```dart
const CyberTab({
  required this.label,
  this.viewName,
  this.cpName = "",
  this.strParameter = "",
  this.objectData,
  this.icon,
  this.badgeCount,
  this.badgeColor,
  this.child,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String` | Label của tab | Required |
| `viewName` | `String?` | Tên view (dùng với V_getView) | null |
| `cpName` | `String` | CP name parameter | "" |
| `strParameter` | `String` | String parameter | "" |
| `objectData` | `dynamic` | Object data | null |
| `icon` | `IconData?` | Icon hiển thị | null |
| `badgeCount` | `int?` | Số đếm badge | null |
| `badgeColor` | `Color?` | Màu badge | null (auto) |
| `child` | `Widget?` | Widget trực tiếp (thay viewName) | null |

⚠️ **Either viewName OR child must be provided**

---

## Ví Dụ Sử Dụng

### 1. Basic Tab View

Simple 3-tab navigation.

```dart
class BasicTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tab View')),
      body: CyberTabView(
        tabs: [
          CyberTab(
            label: 'Home',
            icon: Icons.home,
            child: HomeScreen(),
          ),
          CyberTab(
            label: 'Search',
            icon: Icons.search,
            child: SearchScreen(),
          ),
          CyberTab(
            label: 'Profile',
            icon: Icons.person,
            child: ProfileScreen(),
          ),
        ],
      ),
    );
  }
}
```

### 2. With Badges

Tabs với notification badges.

```dart
CyberTabView(
  tabs: [
    CyberTab(
      label: 'Messages',
      icon: Icons.message,
      badgeCount: 5,  // 5 unread messages
      child: MessagesScreen(),
    ),
    CyberTab(
      label: 'Notifications',
      icon: Icons.notifications,
      badgeCount: 12,  // 12 notifications
      badgeColor: Colors.red,  // Red badge
      child: NotificationsScreen(),
    ),
    CyberTab(
      label: 'Settings',
      icon: Icons.settings,
      child: SettingsScreen(),
    ),
  ],
)
```

### 3. Using View Names (V_getView)

Integration với CyberFramework view system.

```dart
CyberTabView(
  tabs: [
    CyberTab(
      label: 'Orders',
      viewName: 'OrderListView',
      cpName: 'OrderCP',
      strParameter: 'status=pending',
    ),
    CyberTab(
      label: 'Products',
      viewName: 'ProductListView',
      cpName: 'ProductCP',
    ),
    CyberTab(
      label: 'Customers',
      viewName: 'CustomerListView',
      cpName: 'CustomerCP',
    ),
  ],
)
```

### 4. Custom Colors

Tùy chỉnh màu sắc.

```dart
CyberTabView(
  tabs: [...],
  
  // Tab bar background
  backColorTab: Colors.blue.shade50,
  
  // Unselected tab text
  textColorTab: Colors.blue.shade700,
  
  // Selected tab background
  selectBackColorTab: Colors.blue,
  
  // Selected tab text
  selectTextColorTab: Colors.white,
  
  // Border radius
  tabBorderRadius: BorderRadius.circular(25),
)
```

### 5. Keep Alive (Cache Views)

Cache views để giữ state khi switch tabs.

```dart
class KeepAliveExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CyberTabView(
      keepAlive: true,  // Views remain in memory
      
      tabs: [
        CyberTab(
          label: 'Form',
          child: ComplexFormScreen(),  // State preserved
        ),
        CyberTab(
          label: 'List',
          child: ScrollableListScreen(),  // Scroll position preserved
        ),
      ],
    );
  }
}
```

### 6. Initial Index

Start với tab cụ thể.

```dart
CyberTabView(
  initialIndex: 2,  // Start at third tab
  
  tabs: [
    CyberTab(label: 'Tab 1', child: Screen1()),
    CyberTab(label: 'Tab 2', child: Screen2()),
    CyberTab(label: 'Tab 3', child: Screen3()),  // This one
  ],
)
```

### 7. Tab Changed Callback

Listen for tab changes.

```dart
class TabChangeExample extends StatefulWidget {
  @override
  State<TabChangeExample> createState() => _TabChangeExampleState();
}

class _TabChangeExampleState extends State<TabChangeExample> {
  int _currentTab = 0;

  void _handleTabChanged(int index) {
    setState(() {
      _currentTab = index;
    });
    
    print('Switched to tab: $index');
    
    // Load data, analytics, etc.
    switch (index) {
      case 0:
        loadHomeData();
        break;
      case 1:
        loadSearchData();
        break;
      case 2:
        loadProfileData();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberTabView(
      onTabChanged: _handleTabChanged,
      
      tabs: [
        CyberTab(label: 'Home', child: HomeScreen()),
        CyberTab(label: 'Search', child: SearchScreen()),
        CyberTab(label: 'Profile', child: ProfileScreen()),
      ],
    );
  }
}
```

### 8. Many Tabs (Scrollable)

Nhiều tabs với scroll.

```dart
CyberTabView(
  isScrollable: true,  // Enable scroll
  tabSpacing: 4,  // Tighter spacing
  
  tabs: [
    CyberTab(label: 'All', child: AllScreen()),
    CyberTab(label: 'Electronics', badgeCount: 12, child: ElectronicsScreen()),
    CyberTab(label: 'Fashion', badgeCount: 8, child: FashionScreen()),
    CyberTab(label: 'Home & Living', child: HomeScreen()),
    CyberTab(label: 'Beauty', badgeCount: 3, child: BeautyScreen()),
    CyberTab(label: 'Sports', child: SportsScreen()),
    CyberTab(label: 'Books', child: BooksScreen()),
  ],
)
```

### 9. Custom Animation

Tùy chỉnh animation.

```dart
CyberTabView(
  animationDuration: Duration(milliseconds: 400),
  animationCurve: Curves.easeOutCubic,
  
  tabs: [...],
)
```

### 10. Dashboard Example

Complete dashboard với tabs.

```dart
class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => refreshDashboard(),
          ),
        ],
      ),
      
      body: CyberTabView(
        tabs: [
          CyberTab(
            label: 'Overview',
            icon: Icons.dashboard,
            child: OverviewScreen(),
          ),
          
          CyberTab(
            label: 'Sales',
            icon: Icons.trending_up,
            badgeCount: 5,
            badgeColor: Colors.green,
            child: SalesScreen(),
          ),
          
          CyberTab(
            label: 'Orders',
            icon: Icons.shopping_cart,
            badgeCount: 23,
            badgeColor: Colors.orange,
            child: OrdersScreen(),
          ),
          
          CyberTab(
            label: 'Analytics',
            icon: Icons.analytics,
            child: AnalyticsScreen(),
          ),
        ],
        
        keepAlive: true,  // Preserve state
        
        onTabChanged: (index) {
          // Track analytics
          Analytics.logScreenView(
            screenName: ['Overview', 'Sales', 'Orders', 'Analytics'][index],
          );
        },
      ),
    );
  }
}
```

---

## Features

### 1. iOS-Style Design

Segmented pill-style tabs:

```dart
// Auto styling:
// - Rounded pill shape
// - Smooth transitions
// - Shadow on selected
// - Color animations
```

### 2. Lazy Loading

Views chỉ load khi cần:

```dart
// First render: Load initial tab only
// User swipes: Load new tab
// Performance: No upfront cost
```

### 3. Smooth Animation

268ms iOS-standard animation:

```dart
animationDuration: Duration(milliseconds: 268),
animationCurve: Curves.easeInOut,
```

### 4. Auto Scroll

Tab bar tự động scroll:

```dart
// When user swipes to new tab
// Tab bar scrolls to show active tab
// Smooth center-aligned scroll
```

### 5. Badge System

Notification badges:

```dart
CyberTab(
  badgeCount: 5,
  badgeColor: Colors.red,
)
// Auto contrasting text color
// Circular badge design
```

### 6. Keep Alive

Optional view caching:

```dart
keepAlive: true,
// Views stay in memory
// State preserved
// Scroll position maintained
```

### 7. Dual Mode

View name hoặc child:

```dart
// Using child
CyberTab(
  label: 'Home',
  child: HomeScreen(),
)

// Using viewName
CyberTab(
  label: 'Orders',
  viewName: 'OrderListView',
)
```

---

## Best Practices

### 1. Use Child for Simple Screens

```dart
// ✅ GOOD: Direct widget
CyberTab(
  label: 'Home',
  child: HomeScreen(),
)

// ❌ BAD: Unnecessary viewName
CyberTab(
  label: 'Home',
  viewName: 'HomeScreen',
)
```

### 2. Enable Keep Alive for Forms

```dart
// ✅ GOOD: Preserve form state
CyberTabView(
  keepAlive: true,
  tabs: [
    CyberTab(label: 'Form', child: ComplexForm()),
  ],
)

// ❌ BAD: Form resets on tab change
CyberTabView(
  keepAlive: false,  // Form state lost!
)
```

### 3. Use Badges Appropriately

```dart
// ✅ GOOD: Real notifications
badgeCount: unreadCount > 0 ? unreadCount : null,

// ❌ BAD: Always showing zero
badgeCount: 0,  // Don't show if zero
```

### 4. Limit Tabs

```dart
// ✅ GOOD: 3-5 tabs
tabs: [Tab1, Tab2, Tab3, Tab4]

// ⚠️ OK: 6-8 tabs with scroll
isScrollable: true,
tabs: [Tab1, Tab2, ..., Tab8]

// ❌ BAD: Too many tabs
tabs: [Tab1, Tab2, ..., Tab20]  // Use different navigation
```

### 5. Consistent Styling

```dart
// ✅ GOOD: All tabs have icons
CyberTab(label: 'Home', icon: Icons.home),
CyberTab(label: 'Search', icon: Icons.search),

// ❌ BAD: Mixed styles
CyberTab(label: 'Home', icon: Icons.home),
CyberTab(label: 'Search'),  // No icon - inconsistent
```

---

## Troubleshooting

### Tabs không hiển thị

**Nguyên nhân:** Thiếu child hoặc viewName

**Giải pháp:**
```dart
// ✅ CORRECT: Must have child or viewName
CyberTab(
  label: 'Home',
  child: HomeScreen(),
)

// ❌ WRONG: No content
CyberTab(label: 'Home')  // Error!
```

### Animation giật

**Nguyên nhân:** View quá phức tạp

**Giải pháp:**
```dart
// ✅ CORRECT: Use keepAlive
CyberTabView(
  keepAlive: true,  // Pre-cache views
)

// Or optimize view build
```

### Badge không hiển thị

**Nguyên nhân:** badgeCount = 0 hoặc null

**Giải pháp:**
```dart
// ✅ CORRECT: Only show if > 0
badgeCount: count > 0 ? count : null,

// ❌ WRONG: Shows zero
badgeCount: 0,
```

### Tab bar quá rộng

**Nguyên nhân:** isScrollable = false với nhiều tabs

**Giải pháp:**
```dart
// ✅ CORRECT: Enable scroll
CyberTabView(
  isScrollable: true,
  tabs: [...many tabs...],
)
```

### State mất khi đổi tab

**Nguyên nhân:** keepAlive = false

**Giải pháp:**
```dart
// ✅ CORRECT: Enable keepAlive
CyberTabView(
  keepAlive: true,
)
```

---

## Tips & Tricks

### 1. Dynamic Badge Count

```dart
class DynamicBadgeExample extends StatefulWidget {
  @override
  State<DynamicBadgeExample> createState() => _DynamicBadgeExampleState();
}

class _DynamicBadgeExampleState extends State<DynamicBadgeExample> {
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessageCount();
  }

  Future<void> _loadMessageCount() async {
    final count = await getUnreadMessageCount();
    setState(() {
      _messageCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CyberTabView(
      tabs: [
        CyberTab(
          label: 'Messages',
          icon: Icons.message,
          badgeCount: _messageCount > 0 ? _messageCount : null,
          child: MessagesScreen(
            onMessageRead: () {
              setState(() {
                _messageCount = max(0, _messageCount - 1);
              });
            },
          ),
        ),
      ],
    );
  }
}
```

### 2. Programmatic Tab Change

```dart
class ProgrammaticTabExample extends StatefulWidget {
  @override
  State<ProgrammaticTabExample> createState() => _ProgrammaticTabExampleState();
}

class _ProgrammaticTabExampleState extends State<ProgrammaticTabExample>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  void goToTab(int index) {
    _controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return CyberTabView(
      // Use external controller if needed
      tabs: [...],
    );
  }
}
```

### 3. Conditional Tabs

```dart
List<CyberTab> getTabs(User user) {
  final tabs = <CyberTab>[
    CyberTab(label: 'Home', child: HomeScreen()),
    CyberTab(label: 'Search', child: SearchScreen()),
  ];

  if (user.isAdmin) {
    tabs.add(
      CyberTab(
        label: 'Admin',
        icon: Icons.admin_panel_settings,
        child: AdminScreen(),
      ),
    );
  }

  return tabs;
}

CyberTabView(tabs: getTabs(currentUser))
```

### 4. Custom Tab Content

```dart
CyberTab(
  label: 'Special',
  child: CustomScrollView(
    slivers: [
      SliverAppBar(
        title: Text('Special Tab'),
        floating: true,
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(title: Text('Item $index')),
          childCount: 100,
        ),
      ),
    ],
  ),
)
```

### 5. Refresh on Tab Change

```dart
CyberTabView(
  onTabChanged: (index) {
    switch (index) {
      case 0:
        homeKey.currentState?.refresh();
        break;
      case 1:
        searchKey.currentState?.refresh();
        break;
      case 2:
        profileKey.currentState?.refresh();
        break;
    }
  },
  tabs: [...],
)
```

---

## Performance Tips

1. **Use Keep Alive Wisely**: Only for complex views
2. **Optimize Views**: Heavy views = slower tabs
3. **Lazy Load Data**: Load data when tab becomes active
4. **Limit Badges**: Don't update too frequently
5. **Pre-cache Images**: Load tab icons upfront

---

## Common Patterns

### Bottom Navigation Style

```dart
CyberTabView(
  tabs: [
    CyberTab(
      label: 'Home',
      icon: Icons.home,
      child: HomeScreen(),
    ),
    CyberTab(
      label: 'Explore',
      icon: Icons.explore,
      child: ExploreScreen(),
    ),
    CyberTab(
      label: 'Profile',
      icon: Icons.person,
      child: ProfileScreen(),
    ),
  ],
)
```

### Settings Sections

```dart
CyberTabView(
  tabs: [
    CyberTab(
      label: 'General',
      child: GeneralSettings(),
    ),
    CyberTab(
      label: 'Privacy',
      child: PrivacySettings(),
    ),
    CyberTab(
      label: 'Notifications',
      badgeCount: pendingChanges,
      child: NotificationSettings(),
    ),
  ],
)
```

### Data Dashboard

```dart
CyberTabView(
  keepAlive: true,
  tabs: [
    CyberTab(
      label: 'Today',
      child: TodayDashboard(),
    ),
    CyberTab(
      label: 'Week',
      child: WeekDashboard(),
    ),
    CyberTab(
      label: 'Month',
      child: MonthDashboard(),
    ),
  ],
)
```

---

## Platform Compatibility

### iOS
- ✅ Full support
- Native-like feel
- Smooth gestures

### Android
- ✅ Full support
- Material Design friendly
- Swipe navigation

### Web
- ✅ Full support
- Mouse/touch support

### Desktop
- ✅ Full support
- Keyboard navigation

---

## Accessibility

```dart
// Tabs are accessible by default
// - Screen reader support
// - Keyboard navigation
// - Touch targets 44x44+
```

---

## Version History

### 1.0.0
- Initial release
- iOS-style segmented tabs
- Lazy loading
- Smooth animation (268ms)
- Auto scroll
- Badge support
- Icon support
- Keep alive option
- Dual mode (viewName/child)
- Scrollable tabs
- Custom colors
- Tab change callback

---

## License

MIT License - CyberFramework
