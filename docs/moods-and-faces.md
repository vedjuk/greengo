# Moods and faces

Every time Greengo's mood changes, he picks a face and a line at random from that mood's list. Faces are always 5 columns wide (`[` + 3 characters + `]`) so the boater sits straight on his head.

## Moods

| Mood | Triggered by | Faces | How he moves | Sample lines |
|---|---|---|---|---|
| **boot** | a session starts | `[•ᴗ•]` `[¬‿¬]` `[-_•]` `[•_•]` | waves `/`, tips his hat | "howdy, partner! 🤠" · "badges? we don't need no stinkin' badges ⭐" · "I'm your huckleberry 🤠" |
| **listen** | you send a prompt | `[•_•]` `[≖_≖]` `[¬_¬]` `[-_•]` `[•ᴗ•]` | blinks | "head 'em up, move 'em out 🐄" · "say when, partner" · "let's ride 🐎" |
| **blush** | your prompt says please, thanks, bitte or danke | `[≧ᴗ≦]` `[¬‿¬]` `[-‿-]` | tips his hat | "much obliged 🤠" · "aw, shucks 💚" · "mighty fine manners, partner 🎩" |
| **work** | Claude uses a tool | `[•_•]` `[≖_≖]` `[ò_ó]` `[-_•]` `[¬_¬]` `[•ᴗ•]` | swings his lasso `┌[≖_≖]┘~◯` | "it's high noon for app.ts 🕛" · "who are those guys? 🐎" · "catchin' the 3:10 to origin 🚂" |
| **wait** | Claude needs your OK, or it's your turn | `[¬_¬]` (with a cigarillo `╾~`) `[•_•]` `[≖_≖]` | smoke drifts, or `?` `!` | "call it, friendo 🪙" · "fill yer hand, partner ✋" · "yer move, partner 🎲" |
| **error** | a tool fails or the API hiccups | `[ò_ó]` `[×_×]` `[-_-]` `[ó_ò]` | turns red | "well, shoot 🌵" · "deserve's got nothin' to do with it ⚠️" · "remember the Alamo ⚠️" |
| **happy** | Claude finishes | `[^ᴗ^]` (rare) `[¬‿¬]` `[-‿-]` | tips his hat, `\[^ᴗ^]/` for the big grin | "ridin' off into the sunset 🌅" · "another bug bites the dust 🌵" · "the good, the bad and the shipped ✅" |
| **idle** | 20 seconds after happy or blush, 30 after an error | rotates every 30 seconds: `[•_•]` `[¬_¬]╾~` `[≖_≖]` `[-_•]` `[•ᴗ•]` `` [´-`] `` | blinks | "whittlin' 🪵" · "chewin' on a straw 🌾" · "watchin' the tumbleweeds 🌵" |
| **sleep** | 90 quiet seconds | `[-_-]` | snores z · zZ · zZz | talks in his sleep: "Shane… come back… 💤" · "countin' sheep… er, cattle 🐄" |

## Late at night

From 11pm to 5am Greengo gets weary. His idle faces turn to `` [´-`] `` `[=_=]` `[-_•]`, he sleeps as `[=_=]`, and his idle chatter changes to "burnin' the midnight oil 🕯️", "one more and then bed…" and "the saloon's closin' 🍻".

## Work lines by tool

| What Claude does | Example lines |
|---|---|
| Read a file | "readin' auth.ts 📜" · "sizin' up auth.ts 🤨" · "checkin' auth.ts for outlaws 🔍" |
| Edit a file | "patchin' up app.ts 🔨" · "wranglin' app.ts 🪢" · "brandin' app.ts 🔥" |
| Write a new file | "stakin' a claim: utils.ts ⛏️" · "buildin' a homestead: utils.ts 🏠" |
| Search the code | "followin' the tracks 🐾" · "pannin' for gold ⛏️" |
| Search or fetch the web | "pony express to the web 🐎" · "checkin' the telegraph 📨" |
| Start a subagent | "roundin' up a posse 🐎" · "the magnificent seven, ridin' out 🐎" |
| Run tests | "testin' the herd 🧪" · "the good, the bad and the buggy 🧪" · "fastest tests in the west 🧪" |
| `git commit` | "signin' the ledger ✍️" · "for a few commits more ✍️" |
| `git push` | "tell 'em I'm comin' 🌄" · "catchin' the 3:10 to origin 🚂" |
| Install packages | "stockin' up at the general store 📦" · "a fistful of dependencies 📦" |
| Build | "raisin' the barn 🏗️" · "layin' the railroad 🚂" |
| Lint or format | "polishin' the spurs ✨" · "shinin' the badge ⭐" |
| Delete files | "sweepin' the saloon 🧹" · "think I used enough dynamite? 🧨" |
| MCP tools | "wirin' a telegram to github 📨" · "parleyin' with github 🤝" |
| Compact the context | "packin' the saddlebags 🧹" · "travelin' light 🎒" |

The full lists are in `greengo.sh`. [Customizing](customizing.md) shows how to add your own.
