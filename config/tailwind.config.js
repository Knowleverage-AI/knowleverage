const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'chat-primary': '#2563eb',
        'chat-secondary': '#1e40af',
        'chat-success': '#16a34a',
        'chat-error': '#dc2626',
      },
      spacing: {
        'chat-input': '3.75rem',
        'chat-log': '24rem',
      },
      screens: {
        'chat-sm': '480px',
        'chat-md': '768px',
        'chat-lg': '1024px',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
