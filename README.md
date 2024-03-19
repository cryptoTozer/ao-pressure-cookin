# Pressure cookin'

Introducing a collaborative game where you must work together to make glorious soups.
You are in the kitchen with your fellow chefs. Some have access to areas that others don't.
New orders are constantly coming through. Someone's gotta chop the onions and tomatos, and put it in the pot
And whose gonna get the plates??? Oh, careful, looks like that soup on the pot is going to burn soon!
Fulfill enough orders and double your CRED. Burn the kitchen down, and your CRED goes down with it

## To setup yourself

1. Install aos and create an aos process with a cron

```
aos pressureCookin --cron 15-seconds
```

2. Load up the arena blueprinnt

```lua
.load-blueprint arena
```

3. load up the ao-pressure-cookin logic

```lua
.load src/ao-pressure-cookin.lua
```

4. create or connect to a token

```lua
.load-blueprint token
```

5. set token to game

```
PaymentToken = ao.id
```

Current Game: `y1qtPBE9YkUl2W_ejGKepfVgYMjcWjJ6lNAPKkqEQwE`
Default Cred/Token: `Y0Mm5Usu_ejPCE8R-PGVW7POgAwQdejiT2KG_Z3_UbI`