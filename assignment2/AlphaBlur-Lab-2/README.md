# Setup

Used a virtual env. Not required if `pyswip` is already installed globally

```
python -m venv venv
source ./venv/bin/activate
pip install git+https://github.com/yuce/pyswip@master#egg=pyswip
```

# Running file

```
python AlphaBlur-Driver.py
```

# Flow of programme.

1. Enter Prolog File Name (Must be same directory as Driver).
2. Select Map Choice (Customised, Random, AlphaBlur's Map).
3. Select Game Mode (Manual movements, Exploration).
4. Game mode starts.

# Note

1. Manual Movement allow testing of entering portal and killed by wumpus, whereas Exploration would terminate the programme. This is because of the nature of explore/1, which should only return a safe path to an unvisited cell.

2. Correctness Evaluation is done after every action/movement done by Agent such as move/2 and reposition/1.
