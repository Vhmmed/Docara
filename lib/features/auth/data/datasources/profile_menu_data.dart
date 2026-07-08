class ProfileMenuData {
  static const List<Map<String, dynamic>> accountItems = [
    {
      'icon': 'assets/icons/profile.svg',
      'title': 'Edit Profile',
      'route': '/edit-profile',
    },
    {
      'icon': 'assets/icons/notification.svg',
      'title': 'Notifications',
      'route': '/notifications',
    },
    {
      'icon': 'assets/icons/security.svg',
      'title': 'Privacy & Security',
      'route': '/privacy',
    },
  ];

  static const List<Map<String, dynamic>> supportItems = [
    {
      'icon': 'assets/icons/SVG-3.svg',
      'title': 'Help Center',
      'route': '/help',
    },
    {
      'icon': 'assets/icons/SVG-4.svg',
      'title': 'Terms & Conditions',
      'route': '/terms',
    },
  ];

  static const List<Map<String, dynamic>> professionalItems = [
    {
      'icon': 'assets/icons/SVG.svg',
      'title': 'Working Hours',
      'route': '/working-hours',
    },
    {
      'icon': 'assets/icons/SVG-2.svg',
      'title': 'Consultation Fees',
      'route': '/consultation-fees',
    },
  ];

  static List<Map<String, dynamic>> getMenuItems(String roleId) {
    final List<Map<String, dynamic>> items = [];

    items.addAll(accountItems);

    if (roleId == 'doctor') {
      items.addAll(professionalItems);
    }

    items.addAll(supportItems);

    return items;
  }
}