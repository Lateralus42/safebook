Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (sequelize) ->
  return sequelize.define('Message', {
    id:
      type: Sequelize.STRING
      primaryKey: true
    user_id:
      type: Sequelize.STRING
    destination_id:
      type: Sequelize.STRING
    destination_type:
      type: Sequelize.STRING
    hidden_content:
      type: Sequelize.TEXT
  }, {
    updatedAt: false
  })
