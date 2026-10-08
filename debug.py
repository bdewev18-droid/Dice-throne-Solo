import os

def check():
    path = "lib/parts/fight_widgets/combat_ai_chat_dock.dart"
    with open(path, "r", encoding="utf-8") as f:
        c = f.read()
    print("Has webbedActive?", "webbedActive;" in c)
    print("Has @override?", "@override" in c)
    print("Index of webbedActive:", c.find("webbedActive;"))
    
    path2 = "lib/parts/fight_widgets/turn_phase_panel.dart"
    with open(path2, "r", encoding="utf-8") as f:
        c2 = f.read()
    print("Has onSettings?", "onSettings" in c2)
    print("Index of onNext:", c2.find("onNext,"))

check()
