import sys

f = open(sys.argv[1], "r")

while True:
	word = f.read(4)

	if not word: break

	sys.stdout.write(word[::-1])

