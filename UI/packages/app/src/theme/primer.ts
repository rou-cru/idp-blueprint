import {
  createUnifiedTheme,
  genPageTheme,
  palettes,
  shapes,
} from '@backstage/theme';

// GitHub Primer Dark inspired palette
export const primerTheme = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: {
      main: '#58a6ff', // Primer Blue 400
    },
    secondary: {
      main: '#8b949e', // Primer Gray 400
    },
    error: {
      main: '#f85149', // Primer Red 400
    },
    warning: {
      main: '#d29922', // Primer Yellow 500
    },
    info: {
      main: '#58a6ff', // Primer Blue 400
    },
    success: {
      main: '#3fb950', // Primer Green 400
    },
    background: {
      default: '#0d1117', // Canvas Default
      paper: '#161b22',   // Canvas Subtler
    },
    banner: {
      info: '#044289', // Blue 800
      error: '#a40e26', // Red 800
      text: '#c9d1d9', // FG Default
      link: '#58a6ff',
    },
    errorBackground: '#a40e26',
    warningBackground: '#9e6a03', // Yellow 800
    infoBackground: '#044289',
    navigation: {
      background: '#010409', // Canvas Inset
      indicator: '#f78166', // Orange 500 (GitHub Actions orange)
      color: '#c9d1d9',
      selectedColor: '#ffffff',
    },
  },
  defaultPageTheme: 'home',
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"',
  pageTheme: {
    home: genPageTheme({ colors: ['#0d1117', '#0d1117'], shape: shapes.round }),
    documentation: genPageTheme({
      colors: ['#0d1117', '#0d1117'],
      shape: shapes.round,
    }),
    tool: genPageTheme({ colors: ['#0d1117', '#0d1117'], shape: shapes.round }),
    service: genPageTheme({
      colors: ['#0d1117', '#0d1117'],
      shape: shapes.round,
    }),
    website: genPageTheme({
      colors: ['#0d1117', '#0d1117'],
      shape: shapes.round,
    }),
    library: genPageTheme({
      colors: ['#0d1117', '#0d1117'],
      shape: shapes.round,
    }),
    other: genPageTheme({ colors: ['#0d1117', '#0d1117'], shape: shapes.round }),
    app: genPageTheme({ colors: ['#0d1117', '#0d1117'], shape: shapes.round }),
    apis: genPageTheme({ colors: ['#0d1117', '#0d1117'], shape: shapes.round }),
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          backgroundColor: '#0d1117',
          color: '#c9d1d9',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none', // Remove elevation overlay in dark mode
          backgroundColor: '#161b22', // Canvas Subtler
          border: '1px solid #30363d', // Border Subtler
          boxShadow: 'none !important',
        },
        elevation1: {
          boxShadow: 'none',
        },
        elevation2: {
          boxShadow: 'none',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: 'none',
          border: '1px solid #30363d',
          borderRadius: '6px',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          boxShadow: 'none',
          borderBottom: '1px solid #30363d',
          backgroundColor: '#161b22', // Header bg
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: '6px',
          textTransform: 'none',
          fontWeight: 600,
        },
        contained: {
          boxShadow: 'none',
        },
        containedPrimary: {
          backgroundColor: '#238636', // Button Success
          color: '#ffffff',
          '&:hover': {
            backgroundColor: '#2ea043',
          },
        },
      },
    },
    MuiInputBase: {
      styleOverrides: {
        root: {
          backgroundColor: '#0d1117',
          border: '1px solid #30363d',
          borderRadius: '6px',
          padding: '2px 8px',
          '&$focused': {
            borderColor: '#58a6ff',
            boxShadow: '0 0 0 3px rgba(88, 166, 255, 0.3)',
          },
        },
      },
    },
    // Override Backstage specific components if necessary
    BackstageHeader: {
      styleOverrides: {
        header: {
          backgroundImage: 'none',
          backgroundColor: '#161b22',
          borderBottom: '1px solid #30363d',
          boxShadow: 'none',
        },
      },
    },
  },
});
