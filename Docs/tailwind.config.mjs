/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Clerk-inspired brand colors
        brand: {
          purple: '#6C47FF',
          'purple-light': '#8B6DFF',
          'purple-dark': '#5533DD',
        },
        accent: {
          yellow: '#FFF963',
          cyan: '#38DAFD',
        },
        // Dark theme color scale
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
        // Semantic colors
        success: '#22C55E',
        warning: '#FB923C',
        danger: '#EF4444',
        info: '#3B82F6',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['Geist Mono', 'ui-monospace', 'SFMono-Regular', 'Consolas', 'monospace'],
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '112': '28rem',
        '128': '32rem',
      },
      fontSize: {
        '2xs': ['0.625rem', { lineHeight: '0.875rem' }],
      },
      boxShadow: {
        'purple-glow': '0 0 20px rgba(108, 71, 255, 0.15)',
        'purple-glow-lg': '0 0 40px rgba(108, 71, 255, 0.25)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
