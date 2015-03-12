#!/usr/bin/python

f_read = open ("small.log", "r")
f_write = open ("eingangs_testvektor.csv", "w")

blub = 0

for line in f_read:
	zuordnung = line.split("=")
	if line[0] == '#':
		if blub == 1:
			break
		else:
			blub = 1
	if len(zuordnung) > 1:
		if(zuordnung[0] == "S->L_z2"):
			if(zuordnung[1] == "0\n"):
				f_write.write("BLANK;0\n")
				f_write.write(zuordnung[0] + "(part1);" + zuordnung[1])
				f_write.write(zuordnung[0] + "(part2);" + zuordnung[1])
			else:
				f_write.write("Warning")
		elif(zuordnung[0] == "S->mp"):
			if(zuordnung[1] == "0\n"):
				f_write.write(zuordnung[0] + "(part1);" + zuordnung[1])
				f_write.write(zuordnung[0] + "(part2);" + zuordnung[1])
			else:
				f_write.write("Warning")
		elif(zuordnung[0] == "S->fast"):
			f_write.write(zuordnung[0] + ";" + zuordnung[1])
			f_write.write("BLANK;0\n")
		else:
			f_write.write(zuordnung[0] + ";" + zuordnung[1])

f_write.close()
f_read.close()


#generiere Testvektoren
f_read = open ("eingangs_testvektor.csv", "r")
f_write = open ("data_in.small", "w")

count = 0

for line in f_read:
	zuordnung = line.split(";")
	if len(zuordnung) > 1:
		if (zuordnung[0] != "k") and (zuordnung[0] != "S->verbose"):
			f_write.write(zuordnung[1])
			count += 1
		if (zuordnung[0] == "wt[12]"):
			f_write.write(str(0)+"\n")
			count += 1
		if (zuordnung[0] == "sr[12]"):
			f_write.write(str(0)+"\n")
			count += 1
f_write.close()
f_read.close()

print count , " dates writen"

########################################################################

f_read = open ("small.log", "r")
f_write = open ("ausgangs_testvektor.csv", "w")

blub = 0

for line in f_read:
	zuordnung = line.split("=")
	if line[0] == '#':
		if blub == 2:
			break
		else:
			blub += 1
	elif blub == 2:
		if len(zuordnung) > 1:
			if(zuordnung[0] == "S->L_z2"):
				if(zuordnung[1] == "0\n"):
					f_write.write("BLANK;0\n")
					f_write.write(zuordnung[0] + "(part1);" + zuordnung[1])
					f_write.write(zuordnung[0] + "(part2);" + zuordnung[1])
				else:
					f_write.write("Warning")
			elif(zuordnung[0] == "S->mp"):
				if(zuordnung[1] == "0\n"):
					f_write.write(zuordnung[0] + "(part1);" + zuordnung[1])
					f_write.write(zuordnung[0] + "(part2);" + zuordnung[1])
				else:
					f_write.write("Warning")
			elif(zuordnung[0] == "S->fast"):
				f_write.write(zuordnung[0] + ";" + zuordnung[1])
				f_write.write("BLANK;0\n")
			else:
				f_write.write(zuordnung[0] + ";" + zuordnung[1])

f_write.close()
f_read.close()


#generiere Testvektoren
f_read = open ("ausgangs_testvektor.csv", "r")
f_write = open ("data_out.small", "w")

count = 0

for line in f_read:
	zuordnung = line.split(";")
	if len(zuordnung) > 1:
		if (zuordnung[0] != "k") and (zuordnung[0] != "S->verbose"):
			f_write.write(zuordnung[1])
			count += 1
		if (zuordnung[0] == "wt[12]"):
			f_write.write(str(0)+"\n")
			count += 1
		if (zuordnung[0] == "sr[12]"):
			f_write.write(str(0)+"\n")
			count += 1
f_write.close()
f_read.close()

print count , " dates writen"
