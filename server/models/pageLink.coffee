Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (sequelize) ->
  return sequelize.define('pageLink', {
    id:
      type: Sequelize.STRING
      primaryKey: true
    page_id:
      type: Sequelize.STRING
    user_id:
      type: Sequelize.STRING
  }, {
    timestamps: false
  })
