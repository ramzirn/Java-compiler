all: parser

parser.tab.h parser.tab.c: parser.y
	bison -d parser.y

lex.yy.c: lex.l parser.tab.h
	flex lex.l

parser: lex.yy.c parser.tab.c
	gcc -o parser parser.tab.c lex.yy.c -lfl

clean:
	rm -f parser parser.tab.* lex.yy.c

test: parser
	./parser < test.java