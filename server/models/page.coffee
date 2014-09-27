Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (sequelize) ->
  return sequelize.define('Page', {
    id:
      type: Sequelize.STRING
      primaryKey: true
    user_id:
      type: Sequelize.STRING
    name:
      type: Sequelize.TEXT
  }, {
    updatedAt: false
  })
