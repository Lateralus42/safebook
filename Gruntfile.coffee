module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      client:
        files:
          'public/js/app.js': [
            'coffee/init.coffee'
            'coffee/helpers/crypto.coffee'
            'coffee/helpers/fileHasher.coffee'
            'coffee/views/*.coffee'
            'coffee/models/*.coffee'
            'coffee/collections/*.coffee'
            'coffee/router/*.coffee'
            'coffee/start.coffee'
          ]
        options: bare: true

    watch:
      all:
        files: ['coffee/**/*']
        tasks: ['coffee']
        options: spawn: false

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['coffee', 'watch']
