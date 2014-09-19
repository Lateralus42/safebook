Sequelize = require 'sequelize'
_         = Sequelize.Utils._

# opti to do :
# 3 uniques => 3 requete sql ?
# Soit 1 requete dans la validation
# Soit des contraintes sur la bdd

module.exports = (sequelize) ->
  return sequelize.define('Message', {
    id:
      type: Sequelize.STRING
      primaryKey: true
    user_id:
      type: Sequelize.STRING
    destination_id:
      type: Sequelize.STRING
    hidden_content:
      type: Sequelize.TEXT
  }, {
    timestamps: false
  })
