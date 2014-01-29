# Description:
#   A quiz, a quiz, my kindgom for a quiz!

fs = require 'fs'
lockfile = require 'lockfile'

module.exports = (robot) ->

  robot.respond /quizticulate( me){0,1}/i, (msg) ->
    lockfile.lock "quiz.json.lock", [], (err) ->
      if err then return

      fs.readFile "quiz.json", (err, contents) ->
        if err
          lockfile.unlock("quiz.json.lock")
          return
        else

        data = JSON.parse(contents);

        if data["current_question"] or data["current_question"] == 0
          question_idx = data["current_question"]
          msg_prefix = "No. You can't have another question. Who do you think you are? Make do with the one everyone else has: "
        else
          question_idx = Math.floor(Math.random() * data["questions"].length)
          data["current_question"] = question_idx

          msg_prefix = "Fine. Here you go. It's pretty easy, but I still don't think you'll get it: "
        
        question = data["questions"][question_idx]
        
        msg.reply(msg_prefix + " \"" + question["question"] + "\"")

        contents = JSON.stringify data
        fs.writeFile "quiz.json", contents, (err)

      lockfile.unlock("quiz.json.lock")

  robot.respond /(?:sir|m'lord|your holiness),? is (?:it|the answer): (.+)/i, (msg) ->
    lockfile.lock "quiz.json.lock", [], (err) ->
      if err then return

      fs.readFile "quiz.json", (err, contents) ->
        if err
          lockfile.unlock("quiz.json.lock")
          return
        else

        data = JSON.parse(contents);

        if data["current_question"] or data["current_question"] == 0
          answer = msg.match[1].toLowerCase().trim()
          if answer == data["questions"][data["current_question"]]["answer"].toLowerCase().trim()
            msg.reply("Okay, you got it right this time. I still think you're as thick as two short planks, but I'll log it in the leaderboard.")
            data["current_question"] = null
            userName = msg["message"]["user"]["name"]
            if not data["leaderboard"]? then data["leaderboard"] = {}
            if not data["leaderboard"][userName]? then data["leaderboard"][userName] = 0
            data["leaderboard"][userName]++

          else
            msg.reply("Are you really this dumb? Your sheer idiocy has been reported to your line manager. In the mean time, try again.")

        else
          msg.reply("What kind of a cretin are you? You can't answer a question that hasn't been asked.")
        contents = JSON.stringify data
        fs.writeFile "quiz.json", contents, (err)

      lockfile.unlock("quiz.json.lock")

  robot.respond /who's doing best?/i, (msg) ->
    lockfile.lock "quiz.json.lock", [], (err) ->
      if err then return

      fs.readFile "quiz.json", (err, contents) ->
        lockfile.unlock("quiz.json.lock")
        if err
          return
        else

        data = JSON.parse(contents);
        response = "I'm too lazy to give you the full leaderboard."
        userName = msg["message"]["user"]["name"]
        userPoints = null
        if data["leaderboard"]? and data["leaderboard"][userName]?
            userPoints = data["leaderboard"][userName]
            response = response + " You've got " + userPoints + " points. Pathetic."

        if data["leaderboard"]?
          maxValue = -1
          winner = null
          for k,v of data["leaderboard"]
            if v > maxValue
              maxValue = v
              winner = k
            else
          if maxValue > -1
            if maxValue == userPoints 
              response = response + " But you're still at the top of the pack. Just shows how abysmally poor your co-workers are."
            else
              response = response + " " + winner + " is beating you, and they're not even that good."

        else
          response = response + " Besides, no-one's answered any questions yet. What a bunch of losers."

        msg.reply(response)


