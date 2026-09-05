
import math

print("Sine*Exp\tCosine")

t = 0
while t < 20:
    print(math.sin(t)*math.exp(-t*0.1), math.cos(t))
    t += 0.1

