enum GamificationTheme {
  litti,
  momo,
  infinityStone,
}

extension GamificationThemeExtension on GamificationTheme {
  String get displayName {
    switch (this) {
      case GamificationTheme.litti:
        return 'Litti';
      case GamificationTheme.momo:
        return 'Momo';
      case GamificationTheme.infinityStone:
        return 'Infinity Stone';
    }
  }

  // Placeholder for assets/emojis
  String get emoji {
    switch (this) {
      case GamificationTheme.litti:
        return '🍘'; // Using a cracker/cookie emoji as approximation for Litti
      case GamificationTheme.momo:
        return '🥟'; // Dumpling emoji for Momo
      case GamificationTheme.infinityStone:
        return '💎'; // Gem emoji for Infinity Stone
    }
  }
  
  String get assetPath {
     // TODO: Replace with actual asset paths if we add images later
     return '';
  }
}
