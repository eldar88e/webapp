module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/frontend/styles/**/*.scss',
    './app/frontend/javascript/**/*.js'
  ],
  safelist: [
    'text-blue-600', 'text-red-600', 'text-green-600', 'text-indigo-600', 'text-purple-600',
    'bg-blue-600', 'bg-red-600', 'bg-green-600', 'bg-indigo-600', 'bg-purple-600',
    'bg-red-800', 'bg-blue-800', 'bg-green-800', 'bg-indigo-800', 'bg-purple-800',
    'w-14', 'h-14'
  ],
}
