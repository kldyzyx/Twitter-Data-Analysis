# input all the Twitter records as csv file
# output the binary file, each line has 28 bytes, including line number,year,month,date,hour,minute,second,zone,longtitue,latitue,user_id
import struct
import csv

with open("I:\\centrohio\\centralohio_tweets.csv","rt",encoding="utf8") as f:
    with open("I:\\centrohio\\centralohio_tweets_b","wb") as newFile:
        datareader = csv.reader(f)
        for line in datareader:
            s1 = datareader.line_num
            line_num =  struct.pack("i",s1)  # 4 bytes
            newFile.write(line_num)
            s2 =int(line[1][0:4])
            year = struct.pack("h",s2)    # 2 bytes
            newFile.write(year)
            s3 =int(line[1][5:7])
            month = struct.pack("b",s3)   # 1 byte
            newFile.write(month)
            s4 =int(line[1][8:10])
            date = struct.pack("b",s4)    # 1 byte
            newFile.write(date)
            s5 =int(line[1][11:13])
            hour = struct.pack("b",s5)    # 1 byte
            newFile.write(hour)
            s6 =int(line[1][14:16])
            minute = struct.pack("b",s6)   # 1 byte
            newFile.write(minute)
            s7 =int(line[1][17:19])
            second = struct.pack("b",s7)   # 1 byte
            newFile.write(second)
            s8 =int(line[1][20:22])
            zone = struct.pack("b",s8)    # 1 byte
            newFile.write(zone)
            s9 =float(line[2])
            lng= struct.pack("f",s9)    # 4 byte
            newFile.write(lng)
            s10 =float(line[3])
            lat= struct.pack("f",s10)    # 4 byte
            newFile.write(lat)
            s11 = int(line[7])
            userid= struct.pack("q",s11)    # 8 byte
            newFile.write(userid)

 
