const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./app/views/**/*.{erb,html}",
    "./app/components/**/*.{erb,rb,html}",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        indigo: {
          600: "var(--color-indigo-600)",
          700: "var(--color-indigo-700)",
        },
        gray: {
          50: "var(--color-gray-50)",
          100: "var(--color-gray-100)",
          200: "var(--color-gray-200)",
          300: "var(--color-gray-300)",
          400: "var(--color-gray-400)",
          500: "var(--color-gray-500)",
          600: "var(--color-gray-600)",
          700: "var(--color-gray-700)",
          800: "var(--color-gray-800)",
          900: "var(--color-gray-900)",
        },
        red: { ...defaultTheme.colors.red },
        green: {
          600: "var(--color-green-600)",
          700: "var(--color-green-700)",
        },
        yellow: {
          500: "var(--color-yellow-500)",
          600: "var(--color-yellow-600)",
        },
      }
    }
  },
  plugins: []
};
