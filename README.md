###### Warning from author
This was literally one of my first scripts I wrote for gmod so im sure you will find some interesting things that I did to make it work.


# Description

Weighted Traitor Selection allows players to be fairly selected to become traitors and have more people become traitors rather then not getting traitor 5 maps in a row. The longer you go with out being traitor the higher chance you have at becoming traitor. Now that might sound like you could determine who the traitor is; However the algorithm is non-deterministic, making it practically impossible to deduce the current traitors (with the exception with only 2 people playing)

Once you become traitor, your weight gets reset down to a default weight.

# Installation
1. Copy the folder `tttweightsystem` into your addons folder.
2. Mysqloo (MySql) - system uses database to keep persistent weights for all the players. The weights are persistent across maps so if you have a 90% chance to become traitor next round and the map changes you will still have the 90% chance in the next map (as long as no one joins who has a higher weight), It also deletes any records older than 3 weeks old (to prevent it from getting cluttered)
3. Run your server once and it will generate a database-template.txt in `garrysmod/data/weightsystem`, copy and rename it to database.txt and edit the settings inside with your database connection info. (keep it in the same folder)

Once the database settings are configured in the database.txt, restart your server or change maps for it to generate the tables. Once the tables are created, thats it! Go gain some weight!

# Commands

**ttt_traitor_chance_command**: Sets the command players can use to see their traitor chance. If ttt_show_traitor_chance is set to 0 this will not work. (default !TC)

**ttt_karma_increase_weight**: If you want people to get a slight increase in weight (0-2 weight) for good karma you have to enable this command. (Default 0)

**ttt_karma_increase_weight_threshold**: This is the minimum amount of karma needed to get the increased weight buff. If they are below it they will just get regular weight. (default 950, based off of the default max karma in regular TTT)

**ttt_show_traitor_chance**: At the beginning of every round it sends out a message stating what your chance is to become traitor in the next round, or in the next map.

**ttt_weight_system_fun_mode**: Allows the players weight to be portrayed onto their model. (default 0) would not suggest this to be on 24/7 more of a fun mode to have on every now and then (0% chance is normal model, 100% chance is much fatter model, everything else is in between) 

![Image of fat person](http://puu.sh/ignmA/0ed089cde9.jpg)

# Admin Commands
**ttt_weightlogs**: (just typed into console) This allows admins to view all players weight and their chance to become traitor. Admins are also able to see a count of how many times each player has been a specific role. In the weight menu you can also get the players SteamID and set their weight back to default or set the weight to what ever you want, giving the player a higher chance or lower chance at becoming traitor in next round.

To gives users permission to `ttt_weightlogs` they must be in an allowed group. Any group you want to have access must be added to the `data/weightsystem/groupperms.txt` file which gets generated on first load of the script.

![Admin menu](https://puu.sh/wxU0C/64f9a81d20.png)

# Group Extra Weight
This feature was requested by a user, with it you have the ability to give certain groups extra weight. For example you can have donators get 1 or 2 extra weight every round to increase their chances of being traitor more often. Like the `database.txt` file a `groupweight-template.txt` will be generated with an example (like below) that you can use. You can also just create the file yourself and name it `groupweight.txt` and make sure it is in `/data/weightsystem/` folder.

```json
{ "1":{ "MaxWeight":10, "GroupName":"[GroupName]", "MinWeight":0 }, "2":{ "MaxWeight":10, "GroupName":"[AnotherGroupName]", "MinWeight":5 } }
```

If you do not want to use this feature simply don't have a file named `groupweight.txt` in the `/data/weightsystem/` folder with a proper configuration.

The settings for the `groupweight.txt` are as follows -

**MinWeight**: The minimum amount of weight you would want added to users in the group.
**MaxWeight**: The maximum amount of weight you would want added to users in the group.
**GroupName**: The group you wish for a random amount between MinWeight and MaxWeight to be added.

As a note, users who are in a group and receive extra weight will be told they are getting extra weight because they are in the group.




