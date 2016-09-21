TelegramBot = require 'node-telegram-bot-api'
Mqtt = require 'mqtt'
Redis = require 'redis'

secret = require './secret.js'
console.log 'Modules loaded'

telegram = new TelegramBot secret.telegram_token, { polling: true }
mqtt = Mqtt.connect { host: secret.mqtthost, port: secret.mqttport, protocolId: 'MQIsdp', protocolVersion: 3 }
redis = Redis.createClient(secret.redisport, secret.redishost)

telegram.getMe().then (data) ->
  console.log 'TELEGRAM Connected as: '+data.id
.catch (err) ->
  console.log 'TELEGRAM Error: '+err

redis.on 'connect', () ->
  console.log 'REDIS Connected to: '+secret.redishost+':'+secret.redisport
redis.on 'error', (error) ->
  console.log 'REDIS Error: '+error

mqtt.on 'connect', ->
  console.log 'MQTT Connected to: '+secret.mqtthost+':'+secret.mqttport
  mqtt.subscribe '/pdostalcz/+'
mqtt.on 'error', (error) ->
  console.log 'MQTT Error: '+error

telegram.onText /^\/echo (.+)$/, (msg, match) ->
  telegram.sendMessage msg.from.id, match[1]

telegram.onText /^\/mqtt (.+)$/, (msg, match) ->
  redis.get match[1], (err, reply) ->
    telegram.sendMessage msg.from.id, reply

telegram.onText /^\/lock$/, (msg, match) ->
  redis.set 'lock', 'locked'
  telegram.sendMessage msg.from.id, "Locked."

telegram.onText /^\/unlock$/, (msg, match) ->
  redis.set 'lock', 'unlocked'
  telegram.sendMessage msg.from.id, "Unlocked."

telegram.onText /^\/lockstat$/, (msg, match) ->
  redis.get 'lock', (err, reply) ->
    if /^locked/g.test reply
      telegram.sendMessage msg.from.id, "Lock: Locked."
    if /^unlocked/g.test reply
      telegram.sendMessage msg.from.id, "Lock: Unlocked."

telegram.onText /^\/tempstat$/, (msg, match) ->
  redis.get 'temp', (err, reply) ->
    telegram.sendMessage msg.from.id, "Temperature: " + reply + "°C"

mqtt.on 'message', (topic, message) ->
  topic = topic.replace /^\/pdostalcz\/([a-zA-Z0-9]+)$/g, '$1'

  if topic != "ttyUSB0"
    redis.set topic.toString(), message.toString()

  if topic == "move" and /sensor/g.test message
    redis.get 'lock', (err, reply) ->
      if /^locked/g.test reply
        telegram.sendMessage 76149459, "MOVE!"

  if topic == "btn" and /^lock/g.test message
    redis.set 'lock', 'locked'
    telegram.sendMessage 76149459, "Locked."

  if topic == "btn" and /^unlock/g.test message
    redis.set 'lock', 'unlocked'
    telegram.sendMessage 76149459, "Unlocked."

