import fiona
import struct
import timeit
import rtree
from shapely.geometry import *
import math
import csv

start = timeit.default_timer()
fname = 'E:\\osu\\research\\cb_2016_us_county_20m\\cb_2016_us_county_20m.shp'
def by28(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(28)
        if rec: yield rec


with open('H:\\world_tweets_binary','rb') as tweet:
    count = 0
    pos1 = []
    for rec in by28(tweet):
        pos = struct.unpack('<ihbbbbbbffq', rec)
        pos2 = pos[1:4]
        if count > 0 and pos1 != pos2:
            print(pos1)
        pos1 = pos2
        count += 1
        if count > 5680:
            break
