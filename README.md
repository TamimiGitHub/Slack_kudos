## Overview

This is the Kudos script that could be integrated with your slack team. The aim of this script is to choose a random "winner" from the mentions during the day by adding them to the pool. The pool weight depends on the number of emoji reactions to the kudos massage.

e.g.
"Kudos to @Peter for getting me coffee today" with 5 reactions will put Peter in the winning pool 6 times
After executing the script, if Peter wins, the bot will mention and tag Peter. The kudos bot will also invite Peter if he left/not in the channel

## How to run
`./kudos.rb` --> Runs locally
`./kudos.rb post` --> Posts results on Slack

## To-Do

- [ ] Implement pagination (in `parseData`)
- [x] Implement count one reaction per person (in `getReactCount`)
- [ ] Implement handling of [user groups](https://api.slack.com/methods/usergroups.users.list). e.g.

```
    {
      "type": "message",
      "user": "U03LD39MS",
      "text": "^ <!subteam^S6DBLTYAG|@ti-devs> and <!subteam^S6RTQMSGH|@ti-testers> (not sure how this is gonna work lol)",
      "ts": "1517945829.000818"
    },
```

- [ ] Implement `opt` for better handling of script parameters
- [x] Avoid multiple nominations of user if mentioned more than one time in the same text
- [ ] Implement handling of mentions in threads
- [ ] Convert to hash:
```
{
  name,
  numVotes
}
```

## Sample Response

```
    {
      "type": "message",
      "user": "U4W979L2D",
      "text": "kudos to <@U04MB7LR4> for answering a ton of questions on stackoverflow",
      "ts": "1517935672.000342",
      "reactions": [
        {
          "name": "+1",
          "users": [
            "U02E8E0JZ",
            "U02E996RG",
            "U3D26AKQ8",
            "U2QA2NGA1",
            "U21CUJ61Z",
            "U04BMTEK7",
            "U034YBKCP",
            "U02E8DX5D",
            "U23N7U05C"
          ],
          "count": 9
        },
        {
          "name": "sock",
          "users": [
            "U02E996RG",
            "U02E8DX5D"
          ],
          "count": 2
        },
        {
          "name": "slightly_smiling_face",
          "users": [
            "U23N7U05C"
          ],
          "count": 1
        }
      ]
    }
```
### Methods

`getChannelHistory` - gets channel history between `start_time` and `end_time` <br />
`getUserIDs` - gets an array of user ids from a slack message <br />
`getUserJSON` - gets user profile from userID <br />
`getUsername` - gets user name from user profile <br />
`getMessagePermalink` - gets the permalink for a given timestamp in the kudos channel <br />
`chooseWinner` - random selector to choose id from pool of nominees <br />
`getReactCount` - get total reactions for a massage <br />
`getStats` - outputs the stats of user entries in pool <br />
`parseData` - parses the channel history to return a pool <br />
`postToSlack` - posts to a slack channel <br />

### Notes

To use, replace:
SLACK_PLUGIN_TOKEN -> With your slack plugin token
CHANNEL_ID -> With your wanted channel ID
Bot_Token - > With your generated bot token
