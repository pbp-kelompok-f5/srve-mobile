import 'package:flutter/material.dart';

const communitiesListRoute = '/communities/list';
const communityDetailRoute = '/communities/detail';
const myCommunitiesRoute = '/communities/mine';
const communityFormRoute = '/communities/form';

const _communityRoutes = {
  communitiesListRoute,
  communityDetailRoute,
  myCommunitiesRoute,
  communityFormRoute,
};

/// Navigates back to the main communities list or, if it's not on the stack,
/// stops at the first non-community route (e.g., the home screen).
void navigateToCommunitiesHome(BuildContext context) {
  Navigator.popUntil(
    context,
    (route) {
      if (route is! PageRoute) return false; // pop overlays (e.g., drawers)
      final name = route.settings.name;
      final isCommunitiesList = name == communitiesListRoute;
      final isOutsideCommunities = !_communityRoutes.contains(name);
      return isCommunitiesList || isOutsideCommunities;
    },
  );
}

/// Closes the drawer first, then returns to the communities home.
void closeDrawerAndNavigateToCommunitiesHome(BuildContext context) {
  Navigator.pop(context);
  navigateToCommunitiesHome(context);
}
