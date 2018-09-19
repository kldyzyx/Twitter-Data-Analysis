#"region": [-83.38, 39.71, -82.41, 40.45]

import struct
import csv
def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: yield rec 
# Ohio extent: [-84.82030499999999,38.403423]-[-80.51845399999999,42.327132]
with open('I:\\world_tweets_ohio','rb') as rf:
    with open('I:\\world_tweets_columbus','wb') as wf:
        count = 0
        for rec in by16(rf):
            pos = struct.unpack('<ihbbff', rec)
            if pos[4] <-82.41:
                if pos[4] > -83.38:
                    if pos[5] > 39.71:
                        if pos[5] < 40.45:
                            line_num = struct.pack("i",pos[0])  # 4 bytes
                            year = struct.pack("h",pos[1]) # 2 byte
                            month = struct.pack("b",pos[2]) # 1 byte
                            date = struct.pack("b",pos[3])  # 1 byte

                            lng =  struct.pack("f",pos[4]) # 4 bytes
                            lat =  struct.pack("f",pos[5]) # 4 bytes
                           
                            wf.write(line_num)
                            wf.write(year)
                            wf.write(month)
                            wf.write(date)
                            wf.write(lng)
                            wf.write(lat)
                            count += 1
        print(count)

# 46717
