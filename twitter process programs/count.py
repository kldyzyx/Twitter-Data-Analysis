import struct
import csv

# unpacking
def by28(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(28)
        if rec: yield rec 

# filter the tweets in us bound box
# USA Extent: (-124.848974, 24.396308) - (-66.885444, 49.384358)
with open('I:\\centrohio\\centralohio_tweets_b', 'rb') as inh:
    count = 0
    for rec in by28(inh):
        count += 1
    print(count)
