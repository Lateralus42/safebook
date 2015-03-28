module.exports = (grunt) ->

  grunt.initConfig
    servers:
      staging: '178.62.243.153'
      production: 'safebook.fr'
    shell:
      deploy:
        command: (where) ->
          'ssh node@178.62.243.153 "cd /var/www/safebook; git clean -f -d; git pull; npm install; grunt coffee:web_client; sudo systemctl restart safebook.service"'
    coffee:
      web_client:
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
      mobile_client:
        files:
          'mobile/www/js/app.js': [
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
  grunt.loadNpmTasks 'grunt-shell'

  grunt.registerTask 'default', ['coffee', 'watch']
