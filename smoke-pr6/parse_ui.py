import re
xml=open(r'C:\Users\user\tahfiz-ui\thafiz_teacher\smoke-pr6\uidump.xml',encoding='utf-8',errors='replace').read()
for m in re.finditer(r'content-desc="([^"]+)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml):
    desc=m.group(1).replace('&#10;',' | ')
    cx=(int(m.group(2))+int(m.group(4)))//2
    cy=(int(m.group(3))+int(m.group(5)))//2
    print(f'{desc} @ {cx},{cy}')
