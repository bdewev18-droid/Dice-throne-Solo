import sys
import json

def main():
    try:
        input_data = sys.stdin.read()
        if not input_data:
            print(json.dumps({"decision": "allow"}))
            return
            
        payload = json.loads(input_data)
        tool_call = payload.get("toolCall", {})
        args = tool_call.get("args", {})
        cmd = args.get("CommandLine", "").lower()
        
        if ("verify-fast.ps1" in cmd or "flutter build" in cmd) and "allow_build=1" not in cmd:
            print(json.dumps({
                "decision": "deny",
                "reason": "INTERDIT : Tu ne peux pas lancer le build directement. Tu DOIS utiliser la compétence (Skill) 'build-workflow' pour garantir l'incrémentation de version."
            }))
        else:
            print(json.dumps({"decision": "allow"}))
            
    except Exception as e:
        # En cas d'erreur de parsing, on autorise pour ne pas tout bloquer
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
