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

def by28(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(28)
        if rec: 
            yield rec 

lng = []
lat = []
with open('I:\\centrohio\\centralohio_tweets_b','rb') as rf:
    count = 0
    for rec in by28(rf):
        coor = struct.unpack('<ihbbbbbbffq', rec)
        lng.append(coor[8])
        lat.append(coor[9])
        count+=1
    print(count)

       
ax.scatter(lng,lat,s=0.01, alpha=0.4)
plt.show()



# 258327 records in ohio tweets
# 3652069 records in this columbus tweets
