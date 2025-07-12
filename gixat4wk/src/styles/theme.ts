export const theme = {
  colors: {
    primary: '#FF3B30', // Apple red
    primaryDark: '#D70015', // Darker red
    secondary: '#FF6B6B', // Light red
    background: '#FFFFFF', // Light background
    surface: '#F8F9FA', // Light surface
    card: '#FFFFFF',
    text: '#000000', // Black text
    textSecondary: '#6C7B7F', // Gray text
    textLight: '#8E8E93', // Light gray
    border: '#E5E5EA', // Light border
    placeholder: '#C7C7CC',
    error: '#FF3B30',
    success: '#34C759',
    warning: '#FF9500',
    
    // Specific to login
    inputBackground: '#F2F2F7',
    buttonShadow: 'rgba(0, 0, 0, 0.1)',
    cardShadow: 'rgba(0, 0, 0, 0.05)',
  },
  
  fonts: {
    regular: 'System',
    medium: 'System',
    bold: 'System',
    sizes: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 20,
      xxl: 24,
      xxxl: 28,
      title: 32,
    },
    weights: {
      light: '300' as const,
      regular: '400' as const,
      medium: '500' as const,
      semibold: '600' as const,
      bold: '700' as const,
    },
  },
  
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 40,
    xxxl: 48,
  },
  
  borderRadius: {
    small: 8,
    medium: 12,
    large: 16,
    xl: 20,
    round: 50,
  },
  
  shadows: {
    small: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 1,
      },
      shadowOpacity: 0.05,
      shadowRadius: 2,
      elevation: 1,
    },
    medium: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 2,
      },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 3,
    },
    large: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 4,
      },
      shadowOpacity: 0.15,
      shadowRadius: 8,
      elevation: 5,
    },
  },
};