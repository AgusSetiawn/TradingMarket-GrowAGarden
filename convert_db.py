import re
import json

# Read Database.lua
with open('Database.lua', 'r', encoding='utf-8') as f:
    lua_content = f.read()

# Extract Pets section
pets_match = re.search(r'Pets = \{(.+?)\}', lua_content, re.DOTALL)
pets_str = pets_match.group(1)
pets = re.findall(r'"([^"]+)"', pets_str)

# Extract Items section  
items_match = re.search(r'Items = \{(.+?)\}', lua_content, re.DOTALL)
items_str = items_match.group(1)
items = re.findall(r'"([^"]+)"', items_str)

# Create JSON
data = {
    "Pets": pets,
    "Items": items
}

# Write to Database.json
with open('Database.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)

print(f"✅ Generated Database.json: {len(pets)} pets + {len(items)} items = {len(pets)+len(items)} total")
