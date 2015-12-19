# Description

Weighted Traitor Selection allows players to be fairly selected to become traitors and have more people become traitors rather then not getting traitor 5 maps in a row. The longer you go with out being traitor the higher chance you have at becoming traitor. Now that might sound like you could determine who the traitor is; However the algorithm is non-deterministic, making it practically impossible to deduce the current traitors (with the exception with only 2 people playing)

Once you become traitor, your weight gets reset down to a default weight.

# Installation
1. Copy the folder "tttweightsystem" into your addons folder.
2. Mysqloo (MySql) - system uses database to keep persistent weights for all the players. The weights are persistent across maps so if you have a 90% chance to become traitor next round and the map changes you will still have the 90% chance in the next map (as long as no one joins who has a higher weight), It also deletes any records any 3 weeks old (to prevent it from getting cluttered)
3. Run server once and it will generate a database-template.txt in garrysmod/data/weightsystem copy and rename it to database.txt and edit the settings inside to use your database settings. (keep it in the same folder)

Once the database settings are configured it will create the table and make sure everything that is needed is there.

# Commands

**ttt_traitor_chance_command**: Sets the command players can use to see their traitor chance. If ttt_show_traitor_chance is set to 0 this will not work. (default !TC)

**ttt_karma_increase_weight**: If you want people to get a slight increase in weight (0-2 weight) for good karma you have to enable this command. (Default 0)

**ttt_karma_increase_weight_threshold**: This is the minimum amount of karma needed to get the increased weight buff. If they are below it they will just get regular weight. (default 950 based off of the default max karma.)

**ttt_show_traitor_chance**: At the beginning of every round it sends out a message stating what your chance is to become traitor in the next round.

**ttt_weight_system_fun_mode**: Allows the players weight to be portrayed onto their model. (default 0) would not suggest this to be on 24/7 more of a fun mode to have on every now and then (0% chance is normal model, 100% chance is much fatter model, everything else is in between) 

![Image of fat person](http://puu.sh/ignmA/0ed089cde9.jpg)

# Admin Commands
**ttt_weightlogs**: (just typed into console) This allows admins to view all players weight and their chance to become traitor. As well as see the count of how many times each player has been a specific role. In the weight menu you can also get the players SteamID and set their weight back to default or set the weight to what ever you want, giving the player a higher chance or lower chance at becoming traitor in next round.

There is "groupperms.txt" in data/weightsystem that is created, it default makes it so admins and superadmins can access the ttt_weightlogs command. Make sure you add in any groups that you would like to have permissions to use the command.

# Group Extra Weight

A feature that was requested was to be able to give people some extra weight based on the group they are in. You can now do this by running the addon on the server at least once and you will see a new file get added into "~/Data/tttweightsystem/" on the server called groupweight-template.txt which looks like the following:

```
{ "1":{ "MaxWeight":10, "GroupName":"[GroupName]", "MinWeight":0 }, "2":{ "MaxWeight":10, "GroupName":"[AnotherGroupName]", "MinWeight":5 } }
```
If you want to use this extra weight system you will need to copy the template and rename it to groupweight.txt and update the json mentioned above. (if you do not want to use this feature just don't bother creating a groupweight.txt file in the folder the addon looks for that specific file):

You will be able to enter the min and max weight (the addon selects a random number between the min and max) and the group name such as "superadmin" or "regular" or "donator". The JSON in the file will be minified but you can bring it into a JSON formatter (http://jsonformatter.curiousconcept.com/) to be able to read it easier. Users will also have it printed out to them that they were given extra weight because they were in a group. I will probably make that optional or remove it in another version.

~[Image of players weights](http://puu.sh/if2C3/6c3a9e50f1.png)
~[Image of players role count](http://puu.sh/if2CK/b71d200977.png)
