import json
import re
print(bool("abc"))
print(bool(123))
print(bool(["apple", "cherry", "banana"]))

x = "Hello"
y = -1

print(bool(x))
print(bool(y))

print(bool(""))
print(bool((1,2)))
print(bool([0,0]))


x = 200
print(isinstance(x, str))


x = ["apple", "banana"]
y = [ "banana","apple"]
z = x
x = {"a":3,"b":x}
print(len(x))

thisset = {"apple", "banana", "cherry"}
thisset.add("orange")
print(thisset)
for x in thisset:
  print(x)

for x in range(3, 50, 6):
  print(x)
for x in range(10):
  print(x)
else:
  print("Finally finished!")
x='{"name":"Bill", "age":"123", "city":"Seatle"}'
y = json.loads(x)
print(y["age"])


x = {
  "name": "Bill",
  "age": 63,
  "married": True,
  "divorced": False,
  "children": ("Jennifer","Rory","Phoebe"),
  "pets": None,
  "cars": [
    {"model": "Porsche", "mpg": 38.2},
    {"model": "BMW M5", "mpg": 26.9}
  ]
}

print(json.dumps(x, indent=0, separators=(" --> ", " = ")))


txt = "China is a great country"
x = re.search("^China.*country$", txt)
print(x)
