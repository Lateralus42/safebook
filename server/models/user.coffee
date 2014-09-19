Sequelize = require 'sequelize'
_         = Sequelize.Utils._

# opti to do :
# 3 uniques => 3 requete sql ?
# Soit 1 requete dans la validation
# Soit des contraintes sur la bdd

module.exports = (sequelize) ->
  return sequelize.define('User', {
    id:
      type: Sequelize.STRING
      unique: true
    pseudo:
      type: Sequelize.STRING
      unique: true
    remote_password_hash:
      type: Sequelize.STRING
    remote_password_salt:
      type: Sequelize.STRING
    pubkey:
      type: Sequelize.TEXT
      unique: true
      # validate: isA:
    hidden_seckey:
      type: Sequelize.TEXT
      # validate: isA:
    hidden_mainkey:
      type: Sequelize.TEXT
      # validate: isA:
  }, {
    instanceMethods:
      public: -> _.pick(@, 'id', 'pseudo', 'pubkey')
      full: ->
        _.pick(@, 'id', 'pseudo', 'pubkey', 'hidden_seckey', 'hidden_mainkey')
    timestamps: false
  })
