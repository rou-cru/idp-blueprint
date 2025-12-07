/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Brand Colors
        brand: {
          purple: '#6C47FF',
          'purple-light': '#8B6DFF',
          'purple-dark': '#5533DD',
        },
        accent: {
          yellow: '#FFF963',
          cyan: '#38DAFD',
        },
        // Status Colors
        success: '#22C55E',
        warning: '#FB923C',
        danger: '#EF4444',
        info: '#3B82F6',
        // Legacy Dark Palette (Keep for transition compatibility)
        dark: {
          50: '#FAFAFA',
          100: '#F5F5F5',
          200: '#E5E5E5',
          300: '#D4D4D4',
          400: '#A3A3A3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          850: '#1F1F1F',
          900: '#171717',
          950: '#0A0A0A',
        },
        // Semantic System (The Truth)
        bg: {
          base: '#000000', // Pure black (Clerk spec)
          elevated: '#121212',
          subtle: '#171717',
          overlay: '#1F1F1F',
          muted: '#262626',
          hover: 'rgba(255, 255, 255, 0.04)',
          active: 'rgba(255, 255, 255, 0.08)',
        },
        text: {
          primary: '#FAFAFA',
          secondary: '#A1A1AA',
          tertiary: '#71717A',
          muted: '#52525B',
          inverted: '#0A0A0A',
        },
        border: {
          default: 'rgba(255, 255, 255, 0.08)',
          hover: 'rgba(255, 255, 255, 0.12)',
          subtle: 'rgba(255, 255, 255, 0.05)',
          emphasis: 'rgba(255, 255, 255, 0.1)',
          focus: 'rgba(108, 71, 255, 0.5)',
        },
        ui: {
          'scrollbar-track': '#171717',
          'scrollbar-thumb': '#404040',
          'scrollbar-hover': '#525252',
          'backdrop': 'rgba(10, 10, 10, 0.6)',
          'backdrop-solid': 'rgba(10, 10, 10, 0.8)',
        },
      },
      fontFamily: {
        sans: ['Geist', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['Geist Mono', 'JetBrains Mono', 'Monaco', 'ui-monospace', 'monospace'],
      },
      spacing: {
        'header-h': '4rem',
        'sidebar-w': '19rem',
        'toc-w': '14rem',
        'content-max': '80rem',
        'container-max': '112.5rem',
      },
      backdropBlur: {
        'header': '16px',
      },
      // Centralized Typography Configuration
      typography: (theme) => ({
        DEFAULT: {
          css: {
            maxWidth: 'none',
            color: theme('colors.text.secondary'),
            '--tw-prose-headings': theme('colors.text.primary'),
            '--tw-prose-links': theme('colors.brand.purple'),
            '--tw-prose-code': theme('colors.brand.purple-light'),
            '--tw-prose-quote-borders': theme('colors.brand.purple'),
            
            h1: {
              color: 'var(--tw-prose-headings)',
              fontWeight: '600', // Semi-bold (Clerk spec)
              letterSpacing: '-0.025em',
            },
            h2: {
              color: 'var(--tw-prose-headings)',
              fontWeight: '600',
              marginTop: '2.5em',
              marginBottom: '1em',
            },
            h3: {
              color: 'var(--tw-prose-headings)',
              fontWeight: '600',
              marginTop: '2em',
              marginBottom: '0.75em',
            },
            a: {
              color: 'var(--tw-prose-links)',
              textDecoration: 'none',
              transition: 'color 0.2s',
              '&:hover': {
                color: theme('colors.brand.purple-light'),
                textDecoration: 'underline',
              },
            },
            code: {
              color: 'var(--tw-prose-code)',
              backgroundColor: theme('colors.bg.elevated'),
              borderRadius: '0.25rem',
              padding: '0.125rem 0.375rem',
              fontWeight: '500',
            },
            'code::before': {
              content: '""',
            },
            'code::after': {
              content: '""',
            },
            blockquote: {
              borderLeftColor: 'var(--tw-prose-quote-borders)',
              backgroundColor: theme('colors.bg.subtle'),
              padding: '0.5rem 1rem',
              borderRadius: '0 0.25rem 0.25rem 0',
              fontStyle: 'normal',
            },
          },
        },
      }),
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}