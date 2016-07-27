moment = require 'moment'
TelegramBot = require 'node-telegram-bot-api'

telegram = new TelegramBot '226026540:AAEroOt-n4COgqA4_H587F37A07l3gCrOU8', { polling: true }

telegram.onText /\/echo (.+)/, (msg, match) ->
  telegram.sendMessage msg.from.id, match[1]

