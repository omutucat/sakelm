/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx,elm}",
    ],
    theme: {
        extend: {
            colors: {
                'primary': '#6a4c93',
                'secondary': '#a895c9',
                'accent': '#f15946',
                'light-gray': '#f5f5f5',
                'medium-gray': '#dddddd',
                'dark-gray': '#888888',
            },
            fontFamily: {
                'sans': ['"Noto Sans JP"', 'sans-serif'],
            }
        },
    },
    plugins: [],
}
