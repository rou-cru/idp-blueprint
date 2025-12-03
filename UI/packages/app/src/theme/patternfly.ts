import {
  createUnifiedTheme,
  genPageTheme,
  palettes,
  shapes,
} from '@backstage/theme';

export const patternflyTheme = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: {
      main: '#EE0000', // Red Hat Red
    },
    secondary: {
      main: '#FFFFFF', // White for secondary actions on dark
    },
    error: {
      main: '#C9190B',
    },
    warning: {
      main: '#F0AB00',
    },
    info: {
      main: '#0066CC',
    },
    success: {
      main: '#3E8635',
    },
    background: {
      default: '#151515', // Dark background
      paper: '#1b1d21',   // Slightly lighter for cards
    },
    banner: {
      info: '#0066CC',
      error: '#C9190B',
      text: '#FFFFFF',
      link: '#FFFFFF',
    },
    errorBackground: '#C9190B',
    warningBackground: '#F0AB00',
    infoBackground: '#0066CC',
    navigation: {
      background: '#151515',
      indicator: '#EE0000',
      color: '#FFFFFF',
      selectedColor: '#FFFFFF',
    },
  },
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme({ colors: ['#EE0000', '#151515'], shape: shapes.wave }),
    documentation: genPageTheme({
      colors: ['#EE0000', '#151515'],
      shape: shapes.wave,
    }),
    tool: genPageTheme({ colors: ['#EE0000', '#151515'], shape: shapes.round }),
    service: genPageTheme({
      colors: ['#EE0000', '#151515'],
      shape: shapes.wave,
    }),
    website: genPageTheme({
      colors: ['#EE0000', '#151515'],
      shape: shapes.wave,
    }),
    library: genPageTheme({
      colors: ['#EE0000', '#151515'],
      shape: shapes.wave,
    }),
    other: genPageTheme({ colors: ['#EE0000', '#151515'], shape: shapes.wave }),
    app: genPageTheme({ colors: ['#EE0000', '#151515'], shape: shapes.wave }),
    apis: genPageTheme({ colors: ['#EE0000', '#151515'], shape: shapes.wave }),
  },
});
