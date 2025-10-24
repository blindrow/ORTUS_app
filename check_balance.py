import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

if len(sys.argv) < 2:
    print("Usage: python3 check_balance.py path/to/file.dart")
    sys.exit(1)

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

cur_curly = 0
cur_round = 0
cur_square = 0

print("{:>6} {:>6} {:>6} {:>6}  {}".format("LINE","{ }","( )","[ ]","SNIPPET"))
for i,ln in enumerate(lines, start=1):
    s = ln.rstrip("\n")
    out = []
    j=0
    in_s = False
    quote_char = None
    while j < len(s):
        ch = s[j]
        if not in_s and s[j:j+3] in ("'''", '"""'):
            quote_char = s[j:j+3]
            in_s = True
            j += 3
            continue
        if not in_s and ch in ("'", '"'):
            quote_char = ch
            in_s = True
            j += 1
            continue
        if in_s:
            if quote_char in ("'''", '"""'):
                if s[j:j+3] == quote_char:
                    in_s = False
                    quote_char = None
                    j += 3
                    continue
                else:
                    j += 1
                    continue
            else:
                if ch == "\\":
                    j += 2
                    continue
                if ch == quote_char:
                    in_s = False
                    quote_char = None
                    j += 1
                    continue
                j += 1
                continue
        out.append(ch)
        j += 1
    for ch in out:
        if ch == '{': cur_curly += 1
        elif ch == '}': cur_curly -= 1
        elif ch == '(' : cur_round += 1
        elif ch == ')' : cur_round -= 1
        elif ch == '[' : cur_square += 1
        elif ch == ']' : cur_square -= 1
    print("{:6d} {:6d} {:6d} {:6d}  {}".format(i, cur_curly, cur_round, cur_square, s.strip()[:120]))

print("\nFINAL BALANCE: { } = {}, ( ) = {}, [ ] = {}".format(cur_curly, cur_round, cur_square))
if cur_curly != 0 or cur_round != 0 or cur_square != 0:
    print("⚠️  Unbalanced brackets detected. Look for first line where counts become non-zero.")
else:
    print("✅ All bracket counts balance to zero (may still hide context-sensitive syntax errors).")
