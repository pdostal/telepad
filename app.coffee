secret = require './secret.js'

moment = require 'moment'
TelegramBot = require 'node-telegram-bot-api'
Mqtt = require 'mqtt'

telegram = new TelegramBot secret.telegram_token, { polling: true }
mqtt = Mqtt.connect { host: 'iot.siliconhill.cz', port: 1883, protocolId: 'MQIsdp', protocolVersion: 3 }

mqtt.on 'connect', ->
  mqtt.subscribe '/pdostalcz/+'

telegram.onText /\/echo (.+)/, (msg, match) ->
  telegram.sendMessage msg.from.id, match[1]

mqtt.on 'message', (topic, message) ->
  topic = topic.replace /^\/pdostalcz\/([a-zA-Z0-9]+)$/g, '$1'

  if topic != "ttyUSB0"
    telegram.sendMessage 76149459, topic.toString() + ": " + message.toString()

