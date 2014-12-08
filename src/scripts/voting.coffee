# Description
#   Vote on stuff!
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot 投票 開始 p=<purpose> item1, item2, item3, ... - 趣旨および選択肢を設定し、投票受付を開始
#   hubot 投票 趣旨=<purpose> - 趣旨の書き換え
#   hubot 投票 N - N は選択肢の番号または内容
#   hubot 投票 選択肢 - 選択肢の一覧を表示
#   hubot 投票 経過 - 投票の途中経過を表示
#   hubot 投票 終了 - 投票受付を締め切り、結果を表示
#
# Notes:
#   None
#
# Author:
#   antonishen
#   Mako N

module.exports = (robot) ->
  robot.voting = {}

  robot.respond /(?:start vote|(?:投票|採決)(?:\s*)開始)\s+(?:(?:p(?:urpose)?|要旨|主旨|趣旨)=\s*(.+)\s+)?(.+)$/i, (msg) ->

    if robot.voting.votes?
      msg.send "現在、投票期間中です。"
      sendChoices (msg)
    else
      robot.voting.votes = {}
      robot.voting.purpose = msg.match[1]
      createChoices msg.match[2]

      msg.send "投票受付を開始しました。"
      sendChoices(msg)

  robot.respond /(end vote|(投票|採決)\s*(終了|締切))/i, (msg) ->
    if robot.voting.votes?
      console.log robot.voting.votes

      results = tallyVotes()

      response = "投票受付を終了しました。結果は次のとおりです。"
      for choice, index in robot.voting.choices
        response += "\n#{choice}: #{results[index]}"

      msg.send response

      delete robot.voting.votes
      delete robot.voting.choices
    else
      msg.send "終了させる投票はありません。"

  robot.respond /(?:(?:投票|採決)\s*)?(?:purpose(?: of (?:the )?vote)?|p(?==)|要旨|主旨|趣旨)(?:=\s*(.+))?\s*$/i, (msg) ->
    if msg.match[1]?
      robot.voting.purpose = msg.match[1]
      msg.send "投票の趣旨を書き換えました。\n" + robot.voting.purpose
    else
      msg.send robot.voting.purpose if robot.voting.purpose?
    msg.finish()

  robot.respond /(show choices|((投票|採決)\s*)?(選択肢|候補))/i, (msg) ->
    sendChoices(msg)

  robot.respond /(show votes|((投票|採決)\s*)?経過)/i, (msg) ->
    results = tallyVotes()
    sendChoices(msg, results)

  robot.respond /(?:vote(?:\s+for)?|(?:投票|挙手))\s*(.*)\s*$/i, (msg) ->
    return unless robot.voting.votes?

    choice = null

    re = /\d{1,2}$/i
    if re.test(msg.match[1])
      choice = parseInt msg.match[1], 10
    else
      choice = robot.voting.choices.indexOf msg.match[1].trim()

    console.log choice

    sender = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name

    if validChoice choice
      robot.voting.votes[sender] = choice
      msg.send "#{sender} は #{robot.voting.choices[choice]} に投票しました。"
    else
      msg.send "#{sender}: 有効な選択肢ではありません。"
      sendChoices(msg)

  createChoices = (rawChoices) ->
    robot.voting.choices = rawChoices.split(/\s*,\s*/)

  sendChoices = (msg, results = null) ->

    if robot.voting.choices?
      response = ""
      response += robot.voting.purpose + "\n" if robot.voting.purpose?
      for choice, index in robot.voting.choices
        response += "#{index}: #{choice}"
        if results?
          response += " -- 得票: #{results[index]}"
        response += "\n" unless index == robot.voting.choices.length - 1
      msg.send response
    else
      msg.send "現在進行中の投票はありません。"

    msg.finish()

  validChoice = (choice) ->
    numChoices = robot.voting.choices.length - 1
    0 <= choice <= numChoices

  tallyVotes = () ->
    return unless robot.voting.votes?
    results = (0 for choice in robot.voting.choices)

    voters = Object.keys robot.voting.votes
    for voter in voters
      choice = robot.voting.votes[voter]
      results[choice] += 1

    results
