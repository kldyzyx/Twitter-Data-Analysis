import struct
import csv
import matplotlib.pyplot as plt
import struct
import sys

ax = plt.gca()
ax.axis('off')
ax.set_aspect(1)

ax.set_ylim([38.4, 42.33])
ax.set_xlim([-84.821, -80.5])

ax.set_xticks([])
ax.set_yticks([])

def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: 
            yield rec 

lng = []
lat = []
with open('I:\\world_tweets_columbus','rb') as rf:
    count = 0
    for rec in by16(rf):
        coor = struct.unpack('<ihbbff', rec)
        lng.append(coor[4])
        lat.append(coor[5])
        count += 1
    print(count)
       
ax.scatter(lng,lat,s=0.01, alpha=0.4)
plt.show()


# 46717 records in ohio tweets
