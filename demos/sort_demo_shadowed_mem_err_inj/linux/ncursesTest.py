#!/usr/bin/python


import curses, sys
from curses.wrapper import wrapper

def main(stdscr):
    
    
    y, x = window.getmaxyx() # Return a tuple (y, x) of the height and width of the window.


    
    begin_x = 0; begin_y = 0
    height = 1; width = 40
    title = stdscr.subwin(height, width, begin_y, begin_x)
    curses.init_pair(1, curses.COLOR_RED, curses.COLOR_WHITE)
    title.addstr("Hello World", curses.color_pair(1))
    title.refresh()
    
    begin_x = 10; begin_y = 5
    height = 5; width = 40
    statusline = stdscr.subwin(height, width, begin_y, begin_x)
    statusline.addstr("Status OK", curses.A_REVERSE)
    statusline.refresh()
    
    pad = curses.newpad(100, 100)
    #  These loops fill the pad with letters; this is
    # explained in the next section
    for y in range(0, 100):
        for x in range(0, 100):
            try:
                pad.addch(y,x, ord('a') + (x*x+y*y) % 26)
            except curses.error:
                pass
    
    #  Displays a section of the pad in the middle of the screen
    pad.refresh(0,0, 5,5, 20,75)
    
    stdscr.addstr(10,10, "Hello World!")
    stdscr.move(0,0)
    stdscr.refresh()
    # curses.textpad
    
    #
    # Main loop
    # 
    while 1:
        c = stdscr.getch()
        if c == ord('q'):
            sys.exit(0)
        stdscr.refresh()



if __name__ == "__main__":
    wrapper(main)