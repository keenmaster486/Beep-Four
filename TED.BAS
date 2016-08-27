DECLARE FUNCTION DQBinput$ (Layer%, Text$, x%, y%, Col%)
DECLARE SUB LoadLevel ()
DECLARE SUB LoadTiles ()
DECLARE FUNCTION SelectTile% ()
DECLARE SUB SAVE ()
DECLARE SUB DrawTile (tiletodraw%, tx%, ty%)
'$INCLUDE: 'directqb.bi'
'$DYNAMIC
OPTION BASE 0
'TED: A simple level editor for KGE4

CLS

DIM SHARED numoftiles, tilesize, currenttile, copyul, copylr
DIM SHARED copyx1, copyy1, copyx2, copyy2, wherecopiedfrom

OPEN "tiles.dat" FOR INPUT AS #1
INPUT #1, numoftiles 'This should be 4500
DIM SHARED tiletype(numoftiles), tileinf(numoftiles, 5)
FOR I = 1 TO numoftiles
   INPUT #1, tiletype(I), tileinf(I, 1), tileinf(I, 2), tileinf(I, 3), tileinf(I, 4), tileinf(I, 5)
NEXT I


CLOSE

'tilesize = DQBsize(0, 0, 15, 15)
DIM SHARED levelnum, lx, ly, levelname$, leveldesc$, bcolor, foretile(200, 200), backtile(200, 200), midtile(200, 200)

DIM SHARED enemycount, ex(50), ey(50), enum(50)

DIM SHARED cpage

DIM SHARED px, py, pdir

DIM SHARED levelfile$

INPUT "Level to load?", levelnum
IF levelnum < 0 THEN
   PRINT "OK, fine, you want a filespec."
   INPUT "Name of file to load?", levelfile$
END IF
'PRINT "Loading level" + STR$(levelnum);

'PRINT "Done"

'OPEN "enemy.ega" FOR INPUT AS #1
'INPUT #1, numofenemies
'CLOSE


PRINT "Initializing DirectQB..."
temp = DQBinit(30, 0, 0) '30 EMS pages

'DQBfpu

PRINT "Installing keyboard..."
DQBinstallKeyboard


PRINT "Entering VGA mode 13h..."
DQBinitVGA


'Now create a base memory graphics layer:
'dummy& = SETMEM(-66000)
'IF DQBsetBaseLayer(B0) = 0 THEN
'   'Not enough memory
'   dummy& = SETMEM(66000)
'   DQBinitText
'   DQBremoveKeyboard
'   DQBclose
'   PRINT "Out of memory"
'   END
'END IF

'Load tiles:
'(Actually, we don't do this. See after the commented out portion
' for the real routine, which loads from the new TILES.EGA file system)

CLOSE


'DIM SHARED tp(DQBsize(0, 0, 320, 100))
DIM SHARED tempget(DQBsize(0, 0, 47, 47) / 2)



'Load the tiles:
LoadTiles

'Load the level:
LoadLevel


'Main loop:

DQBmouseShow

'Current tile = 1 (default)

currenttile = 1

'Draw background color on layer 2:
DQBboxf 2, 0, 0, 320, 200, bcolor


'DQBsetFrameRate 24



DO UNTIL exitloop = 1

   ctimer! = TIMER
  
   'Clear layer 1:
   DQBclearLayer 1

   'Insert background color:
   DQBcopyLayer 2, 1



   'Draw tiles:
   tempx = INT(-sx / 16)
   tempy = INT(-sy / 16)
   FOR j = tempx TO tempx + INT(320 / 16)
      IF j < 0 OR j > lx THEN GOTO nextonej:
      FOR k = tempy TO tempy + INT(200 / 16) + 1
         IF k < 0 OR k > ly THEN GOTO nextonek:
         'Background tiles:
         IF backtile(j, k) > 0 THEN
            DrawTile backtile(j, k), (j * 16) + sx, (k * 16) + sy
            'Draw a green box on it so we know it's background:
            IF (j * 16) + sx + 7 > 0 AND (j * 16) + sx + 9 < 320 AND (k * 16) + sy + 7 > 0 AND (k * 16) + sy + 9 < 200 THEN DQBbox 1, (j * 16) + sx + 7, (k * 16) + sy + 7, (j * 16) + sx + 9, (k * 16) + sy + 9, 2
         END IF
         'Midground tiles:
         IF midtile(j, k) > 0 THEN
            DrawTile midtile(j, k), (j * 16) + sx, (k * 16) + sy
            'Draw a blue dot on it so we know it's midground:
            IF (j * 16) + sx + 8 > 0 AND (j * 16) + sx + 8 < 320 AND (k * 16) + sy + 8 > 0 AND (k * 16) + sy + 8 < 200 THEN DQBpset 1, (j * 16) + sx + 8, (k * 16) + sy + 8, 1
         END IF

         'Foreground tiles:
         IF foretile(j, k) = 1297 THEN px = (j * 16): py = (k * 16): pdir = 1
         IF foretile(j, k) = 1298 THEN px = (j * 16): py = (k * 16): pdir = -1
         IF foretile(j, k) > 0 AND foretile(j, k) < 10000 THEN DrawTile foretile(j, k), (j * 16) + sx, (k * 16) + sy
         IF foretile(j, k) >= 10000 THEN
            DQBprint 1, RIGHT$(STR$(foretile(j, k)), LEN(STR$(foretile(j, k))) - 1), (j * 16) + sx, (k * 16) + sy, 1
         END IF
         'End-Of-Map tiles:
         IF j = lx AND k <= ly THEN DrawTile 2269, (j * 16) + sx, (k * 16) + sy
         IF k = ly AND j <= lx THEN DrawTile 2269, (j * 16) + sx, (k * 16) + sy
nextonek:
      NEXT k
nextonej:

   NEXT j
  
   'Draw info box (with current cursor position and other stuff):
   tempx = INT((DQBmouseX - sx) / 16)
   tempy = INT((DQBmouseY - sy) / 16)
   DQBboxf 1, 0, 0, 64, 20, 17
   DQBprint 1, STR$(tempx) + "," + STR$(tempy), 0, 0, 15
   DQBprint 1, STR$(foretile(tempx, tempy)) + STR$(midtile(tempx, tempy)), 0, 10, 15

   'Draw enemies text (temp for now):
   FOR I = 1 TO enemycount
      DQBprint 1, "ENEMY" + STR$(enum(I)), ex(I) + sx, ey(I) + sy, 4
      'PLAY "mb l64 c"
   NEXT I

   'Draw mouse cursor:
   tempx = INT((DQBmouseX - sx) / 16)
   tempy = INT((DQBmouseY - sy) / 16)
   DQBbox 1, (tempx * 16) + sx, (tempy * 16) + sy, (tempx * 16) + sx + 16, (tempy * 16) + sy + 16, 15
   DrawTile currenttile, DQBmouseX, DQBmouseY
  
   'Test mouse buttons and place tiles:

   IF DQBkey(42) AND DQBmouseLB THEN  'Shift+LB: custom foreground tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      DQBclearLayer 0
      ans$ = DQBinput(0, "Custom foreground tile value: ", 0, 0, 2)
      foretile(tempx, tempy) = VAL(ans$)
   END IF

   IF DQBmouseLB THEN
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      foretile(tempx, tempy) = currenttile
   END IF

   IF DQBmouseRB THEN 'Delete the foreground tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      foretile(tempx, tempy) = 0
   END IF

   IF DQBkey(48) THEN  'B key: Place a background tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      backtile(tempx, tempy) = currenttile
   END IF

   IF DQBkey(42) AND DQBkey(48) THEN  'Shift+B: Remove a background tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      backtile(tempx, tempy) = 0
   END IF

   IF DQBkey(50) THEN 'M key: Place a midground tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      midtile(tempx, tempy) = currenttile
   END IF
     
   IF DQBkey(42) AND DQBkey(50) THEN 'Shift+M: Remove a midground tile
      tempx = INT((DQBmouseX - sx) / 16)
      tempy = INT((DQBmouseY - sy) / 16)
      midtile(tempx, tempy) = 0
   END IF

   IF DQBkey(38) THEN 'L key (sets level size)
      DQBclearLayer 0
      blah = VAL(DQBinput$(0, "Level X size: ", 0, 0, 15))
      IF blah < 0 THEN blah = 1
      IF blah > 200 THEN blah = 200
      lx = blah
      blah = VAL(DQBinput$(0, "Level Y size: ", 0, 15, 15))
      IF blah < 0 THEN blah = 1
      IF blah > 200 THEN blah = 200
      ly = blah
   END IF

   IF DQBkey(18) THEN 'E key (places an enemy)
      tempx = INT(DQBmouseX - sx)
      tempy = INT(DQBmouseY - sy)
      DQBinitText
      DQBremoveKeyboard
whichenemytoplace: INPUT "Which enemy to place?(0 to delete last enemy placed)", temp
      IF temp > numofenemies OR temp < -1 THEN
         PRINT "Sorry, that enemy doesn't exist."
         PRINT "Choose a number between 0 and" + STR$(numofenemies)
         GOTO whichenemytoplace:
      END IF
      IF temp = 0 THEN
         IF enemycount > 0 THEN enemycount = enemycount - 1
         GOTO skipplaceenemy:
      END IF
      enemycount = enemycount + 1
      ex(enemycount) = tempx
      ey(enemycount) = tempy
      enum(enemycount) = temp
skipplaceenemy:
      DQBinitVGA
      DQBinstallKeyboard
      DQBmouseHide
      DQBmouseShow

'Restore background color to layer 2:
DQBboxf 2, 0, 0, 320, 200, bcolor

   END IF




      IF DQBkey(46) THEN 'C key, for COPY MODE!!! :)
         wherecopiedfrom = 2
         DQBcopyLayer 1, 30
         DO
            IF DQBmouseLB THEN
               DO UNTIL NOT DQBmouseLB
               LOOP
               copyx1 = tempx
               copyy1 = tempy
               EXIT DO
            END IF
          
            tempx = INT((DQBmouseX - sx) / 16)
            tempy = INT((DQBmouseY - sy) / 16)
           
            DQBmouseHide
            DQBcopyLayer 30, 1
            DQBbox 1, (tempx * 16) + sx, (tempy * 16) + sy, (tempx * 16) + sx + 16, (tempy * 16) + sy + 16, 15
            DQBprint 1, "Copy mode:", 225, 0, 15
            DQBprint 1, "Left button", 225, 15, 15
            DQBprint 1, "for upper", 225, 30, 15
            DQBprint 1, "left corner", 225, 45, 15
            DQBcopyLayer 1, 0
            DQBmouseShow
         LOOP
         DO
         
            IF DQBmouseRB THEN
               DO UNTIL NOT DQBmouseRB
               LOOP
               copyx2 = tempx2
               copyy2 = tempy2
               EXIT DO
            END IF
         
            tempx2 = INT((DQBmouseX - sx) / 16)
            tempy2 = INT((DQBmouseY - sy) / 16)
           
            DQBmouseHide
            DQBcopyLayer 30, 1
            DQBbox 1, (tempx * 16) + sx, (tempy * 16) + sy, (tempx * 16) + sx + 16, (tempy * 16) + sy + 16, 15
            DQBbox 1, (tempx * 16) + sx, (tempy * 16) + sy, (tempx2 * 16) + sx + 16, (tempy2 * 16) + sy + 16, 15
            DQBprint 1, "Copy mode:", 225, 0, 15
            DQBprint 1, "Right button", 225, 15, 15
            DQBprint 1, "for lower", 225, 30, 15
            DQBprint 1, "right corner", 225, 45, 15
            DQBcopyLayer 1, 0
            DQBmouseShow
         LOOP

      END IF
   






   IF DQBkey(25) AND NOT wherecopiedfrom = 0 THEN 'P key for PASTE MODE!
      IF wherecopiedfrom = 1 THEN
         tempx = INT((DQBmouseX - sx) / 16)
         tempy = INT((DQBmouseY - sy) / 16)

         emsy = INT(copyul / 18)
         emsx = ((copyul / 18) - INT(copyul / 18)) * 18
         emsy2 = INT(copylr / 18)
         emsx2 = ((copylr / 18) - INT(copylr / 18)) * 18
         
         FOR j = 0 TO (emsx2 - emsx)
            FOR k = 0 TO (emsy2 - emsy)
               IF DQBkey(42) THEN 'left shift then foretile paste
                  foretile(j + tempx, k + tempy) = (j + emsx) + ((k + emsy) * 18)
               ELSEIF DQBkey(54) THEN 'right shift then midtile paste
                  midtile(j + tempx, k + tempy) = (j + emsx) + ((k + emsy) * 18)
               ELSE 'otherwise backtile paste
                  backtile(j + tempx, k + tempy) = (j + emsx) + ((k + emsy) * 18)
               END IF
            NEXT k
         NEXT j

         DO UNTIL NOT DQBkey(25)
         LOOP
      ELSEIF wherecopiedfrom = 2 THEN 'from the main screen
         tempx = INT((DQBmouseX - sx) / 16)
         tempy = INT((DQBmouseY - sy) / 16)
        
         FOR j = 0 TO (copyx2 - copyx1)
            FOR k = 0 TO (copyy2 - copyy1)
               'backtile(j + tempx, k + tempy) = backtile(j + copyx1, k + copyy1)
               'foretile(j + tempx, k + tempy) = foretile(j + copyx1, k + copyy1)
               IF DQBkey(42) THEN 'left shift then foretile paste
                  foretile(j + tempx, k + tempy) = foretile(j + copyx1, k + copyy1)
               ELSEIF DQBkey(54) THEN 'right shift then midtile paste
                  midtile(j + tempx, k + tempy) = midtile(j + copyx1, k + copyy1)
               ELSE 'otherwise backtile paste
                  backtile(j + tempx, k + tempy) = backtile(j + copyx1, k + copyy1)
               END IF

            NEXT k
         NEXT j
      END IF
   END IF




   ''Take care of scrolling:
   'dx = 5
   'dy = 5
   'IF DQBmouseX > 300 THEN
   '   sx = sx - dx
   'END IF
   'IF DQBmouseX < 20 AND sx < 0 THEN
   '   sx = sx + dx
   'END IF
   'IF DQBmouseY > 190 THEN
   '   sy = sy - dy
   'END IF
   'IF DQBmouseY < 10 AND sy < 0 THEN
   '   sy = sy + dy
   'END IF
   '
   'DQBscroll 1, sx, sy
   '

   dx = 10
   dy = 10

   IF DQBmouseX > 300 THEN sx = sx - dx
   IF DQBmouseX < 20 AND sx < 0 THEN sx = sx + dx
   IF DQBmouseY > 190 THEN sy = sy - dy
   IF DQBmouseY < 10 AND sy < 0 THEN sy = sy + dy
  
   IF ABS(sx) > (lx * 16) - 304 THEN sx = -((lx * 16) - 304)
   IF ABS(sy) > (ly * 16) - 194 THEN sy = -((ly * 16) - 194)

   IF sx > 0 THEN sx = 0
   IF sy > 0 THEN sy = 0

   'Flip layers:

   DQBmouseHide
   DQBcopyLayer 1, 0
   DQBmouseShow

   'Check for keys:

   IF DQBkey(56) AND DQBkey(31) THEN SAVE 'Alt+S saves the level
   
   

   
   IF DQBkey(KEYSPACE) THEN
      'Tile selection screen:
      currenttile = SelectTile
   END IF


   IF DQBkey(32) THEN 'D key clears level
      DQBclearLayer 0
      DQBprint 0, "You don't really want to clear the whole", 0, 0, 2
      DQBprint 0, "level, do you? (y,n)", 0, 15, 2
      DO UNTIL exittemp = 1
         IF DQBkey(21) THEN
            FOR j = 0 TO lx
               FOR k = 0 TO ly
                  foretile(j, k) = 0
                  backtile(j, k) = 0
                  midtile(j, k) = 0
               NEXT k
            NEXT j
            EXIT DO
         END IF
         IF DQBkey(49) THEN EXIT DO
      LOOP
      enemycount = 0
   END IF


   IF DQBkey(KEYESC) THEN exitloop = 1 'ESC ends the program


   DO UNTIL TIMER - ctimer! > (1 / 40)
   '   IF DQBkey(KEYESC) THEN EXIT DO
   LOOP

   'DO UNTIL DQBframeReady
   '   'IF DQBkey(KEYESC) THEN EXIT DO
   'LOOP

LOOP


'End program:

DQBclose
DQBinitText

END

REM $STATIC
FUNCTION DQBinput$ (Layer%, Text$, x%, y%, Col%)

'Custom input function by Collin

DO UNTIL DQBkey(KEYENTER) 'Enter key fixes the value
   k$ = DQBinkey$ 'get keypresses
   DQBprint Layer%, Text$ + ans$, x%, y%, Col% 'display text+answer
   IF DQBkey(14) AND NOT ans$ = "" THEN
      DQBboxf Layer%, x% + DQBlen(Text$), y%, x% + DQBlen(Text$) + DQBlen(ans$), y% + 10, 17
      ans$ = LEFT$(ans$, LEN(ans$) - 1)'backspace
      DO UNTIL NOT DQBkey(14)
      LOOP
   END IF
   IF NOT k$ = "" AND NOT DQBkey(14) THEN
      ans$ = ans$ + k$ 'add a character on a keypress
      DQBboxf Layer%, x% + DQBlen(Text$), y%, x% + DQBlen(Text$) + DQBlen(ans$), y% + 10, 17
   END IF
LOOP

DO UNTIL NOT DQBkey(KEYENTER) 'Wait until enter key is lifted
LOOP

DQBinput$ = ans$ 'Return value

END FUNCTION

SUB DrawTile (tiletodraw, tx, ty)

   'Draws a tile at tx,ty on layer 1

'   FOR j = 0 TO 15 STEP 2
'      FOR k = 0 TO 15 STEP 2
'
'         IF NOT tile(tiletodraw, j, k) = 0 THEN
'            DQBpset 1, tx + j, ty + k, tile(tiletodraw, j, k)
'            DQBpset 1, tx + j, ty + k + 1, tile(tiletodraw, j, k + 1)
'            DQBpset 1, tx + j + 1, ty + k, tile(tiletodraw, j + 1, k)
'            DQBpset 1, tx + j + 1, ty + k + 1, tile(tiletodraw, j + 1, k + 1)
'         END IF
'      NEXT k
'   NEXT j

'DQBput 1, tx, ty, VARSEG(tile(0)), VARPTR(tile(0)) + (tilesize * (tiletodraw - 1))



'First, determine the x,y coordinates of the tile in the EMS pages:

emsy = INT(tiletodraw / 18)
emsx = ((tiletodraw / 18) - INT(tiletodraw / 18)) * 18

'IF emsx > 18 THEN emsx = 1

'Now determine which page it's on (from 3 to 21):

emspage = INT(emsy / 12)

'Now change the emsy coordinate to match that page:

emsy = emsy - (emspage * 12)

'IF emsy > 12 THEN emsy = 1

'Now map the emspage to the real pages:

emspage = emspage + 3

'Now get the tile from the ems page:
'emspage = 3
DQBget emspage, emsx * 16, emsy * 16, (emsx * 16) + 15, (emsy * 16) + 15, VARSEG(tempget(0)), VARPTR(tempget(0))

'Now put the tile on page 1:

DQBput 1, tx, ty, VARSEG(tempget(0)), VARPTR(tempget(0))

END SUB

SUB LoadLevel

IF levelfile$ = "" THEN
   OPEN ".\levels\level" + RIGHT$(STR$(levelnum), 1) + ".dat" FOR INPUT AS #1
ELSE
   OPEN ".\levels\" + levelfile$ FOR INPUT AS #1
END IF
INPUT #1, levelname$
PRINT ".";
INPUT #1, leveldesc$
PRINT ".";
INPUT #1, px, py, pdir
PRINT ".";
INPUT #1, lx, ly
PRINT ".";
FOR j = 0 TO lx
   FOR k = 0 TO ly
      INPUT #1, foretile(j, k), midtile(j, k), backtile(j, k)
      'LOCATE 2, 20
      'PRINT STR$(j + (j / 100)) + "%"
   NEXT k
NEXT j
INPUT #1, enemycount
FOR I = 1 TO enemycount
   INPUT #1, ex(I), ey(I), enum(I)
NEXT I
CLOSE



END SUB

SUB LoadTiles

CLOSE 'close all open files

DIM tp(DQBsize(0, 0, 320, 100)) 'create temporary graphics array

DEF SEG = VARSEG(tp(0)) 'set the default segment for BLOAD

FOR h = 1 TO 20 'load the tiles (19 pages)
   dpage = h + 2
  
   IF LEN(STR$(h)) = 2 THEN FileName$ = ".\graphics\tiles" + "0" + RIGHT$(STR$(h), 1) + ".EGA"
   IF LEN(STR$(h)) = 3 THEN FileName$ = ".\graphics\tiles" + RIGHT$(STR$(h), 2) + ".EGA"
 
   DQBclearLayer 0
   DQBprint 0, "Loading tiles: page number" + STR$(h) + "/19", 0, 0, 2
 
   BLOAD FileName$, VARPTR(tp(0))
   DQBput dpage, 0, 0, VARSEG(tp(0)), VARPTR(tp(0))
NEXT h

DEF SEG

CLOSE


END SUB

SUB SAVE

'DQBinitText

'LOCATE 1, 1
'PRINT "Saving level...";
DQBclearLayer 1
DQBclearLayer 0


OPEN ".\levels\level" + RIGHT$(STR$(levelnum), 1) + ".dat" FOR OUTPUT AS #2
WRITE #2, levelname$
WRITE #2, leveldesc$
WRITE #2, px, py, pdir
WRITE #2, lx, ly
FOR j = 0 TO lx
   FOR k = 0 TO ly
      'LOCATE 1, 20
      'PRINT STR$(j * (j / 100)) + "%"
      WRITE #2, foretile(j, k), midtile(j, k), backtile(j, k)
   NEXT k
   'LOCATE 1, 20
   'PRINT STR$((j / lx) * 100) + "%"
   IF j / 4 = INT(j / 4) THEN
      DQBclearLayer 1
      DQBprint 1, "Saving level..." + STR$((j / lx) * 100) + "%", 0, 0, 2
      DQBcopyLayer 1, 0
   END IF
NEXT j
WRITE #2, enemycount
FOR I = 1 TO enemycount
   WRITE #2, ex(I), ey(I), enum(I)
NEXT I

'PRINT "Done."
CLOSE

'DQBinitVGA
'DQBmouseShow

END SUB

FUNCTION SelectTile


   DQBclearLayer 0
   DQBclearLayer 1
   DQBmouseShow
   DO UNTIL exittemp = 1

      IF DQBkey(46) THEN 'C key, for COPY MODE!!! :)
         wherecopiedfrom = 1
         DO
            IF DQBmouseLB THEN
               DO UNTIL NOT DQBmouseLB
               LOOP
               copyul = tiletodraw
               EXIT DO
            END IF
           
            tempx = INT(DQBmouseX / 16)
            tempy = INT(DQBmouseY / 16)
            tiletodraw = tempx + (tempy * 18) + ((cpage - 3) * 216)
  
            DQBmouseHide
            DQBcopyLayer cpage, 1
            DQBbox 1, tempx * 16, tempy * 16, (tempx * 16) + 16, (tempy * 16) + 16, 2
            DQBprint 1, "Copy mode:", 275, 0, 15
            DQBprint 1, "Left button", 275, 15, 15
            DQBprint 1, "for upper", 275, 30, 15
            DQBprint 1, "left corner", 275, 45, 15
            DQBcopyLayer 1, 0
            DQBmouseShow
         LOOP
         DO
          
            IF DQBmouseRB THEN
               DO UNTIL NOT DQBmouseRB
               LOOP
               copylr = tiletodraw
               EXIT DO
            END IF
          
            tempx2 = INT(DQBmouseX / 16)
            tempy2 = INT(DQBmouseY / 16)
            tiletodraw = tempx2 + (tempy2 * 18) + ((cpage - 3) * 216)
 
            DQBmouseHide
            DQBcopyLayer cpage, 1
            DQBbox 1, tempx2 * 16, tempy2 * 16, (tempx2 * 16) + 16, (tempy2 * 16) + 16, 2
            DQBbox 1, tempx * 16, tempy * 16, (tempx2 * 16) + 16, (tempy2 * 16) + 16, 15
            DQBprint 1, "Copy mode:", 275, 0, 15
            DQBprint 1, "Right button", 275, 15, 15
            DQBprint 1, "for lower", 275, 30, 15
            DQBprint 1, "right corner", 275, 45, 15
            DQBcopyLayer 1, 0
            DQBmouseShow
         LOOP

      END IF
      '------------------Done with copy mode-----------------

      '-----------------Tile info changing code--------------
         IF DQBmouseRB THEN
            DQBclearLayer 0
            exittemp = 0
            DO UNTIL exittemp = 1
               DQBclearLayer 1
               DQBboxf 1, 0, 0, 320, 200, 8
               DrawTile tiletodraw, 300, 0
               DQBprint 1, "TILE INFO EDITOR (press x to exit)", 0, 0, 4
               DQBprint 1, "UP/DOWN: Tile type; W/S: Tile info 1", 0, 15, 2
               DQBprint 1, "Press M to manually change values", 0, 30, 2
               SELECT CASE tiletype(tiletodraw)
                  CASE 0
                     DQBprint 1, "Current tile type: 0 (Nothing)", 0, 45, 3
                  CASE 1
                     DQBprint 1, "Current tile type: 1 (Complete Blocking)", 0, 45, 3
                  CASE 2
                     DQBprint 1, "Current tile type: 2 (Block on top)", 0, 45, 3
                  CASE 3
                     DQBprint 1, "Current tile type: 3 (Door: opens to key)", 0, 45, 3
                  CASE 4
                     DQBprint 1, "Current tile type: 4 (Animated)", 0, 45, 3
                  CASE 5
                     DQBprint 1, "Current tile type: 5 (Item)", 0, 45, 3
                  CASE 6
                     DQBprint 1, "Current tile type: 6 (Exit sign)", 0, 45, 3
                  CASE 7
                     DQBprint 1, "Current tile type: 7 (Pole)", 0, 45, 3
                  CASE 8
                     DQBprint 1, "Current tile type: 8 (Slope)", 0, 45, 3
                  CASE 9
                     DQBprint 1, "Current tile type: 9 (End of Map)", 0, 45, 3
                  CASE 10
                     DQBprint 1, "Current tile type: 10 (Portal)", 0, 45, 3
                  CASE 11
                     DQBprint 1, "Current tile type: 11 (Horizontal door)", 0, 45, 3
                  CASE 12
                     DQBprint 1, "Current tile type: 12 (Elevator)", 0, 45, 3
                  CASE 13
                     DQBprint 1, "Current tile type: 13 (Switch)", 0, 45, 3
                  END SELECT
               DQBprint 1, "Current tile info (item value):" + STR$(tileinf(tiletodraw, 1)), 0, 60, 3

               'Tile type up/down change:
               IF DQBkey(KEYUP) THEN
                  DO UNTIL NOT DQBkey(KEYUP)
                  LOOP
                  tiletype(tiletodraw) = tiletype(tiletodraw) + 1
               END IF
               IF DQBkey(KEYDOWN) THEN
                  DO UNTIL NOT DQBkey(KEYDOWN)
                  LOOP
                  tiletype(tiletodraw) = tiletype(tiletodraw) - 1
               END IF
               IF tiletype(tiletodraw) < 0 THEN tiletype(tiletodraw) = 0
               IF tiletype(tiletodraw) > 13 THEN tiletype(tiletodraw) = 13
              
               'Tile info 1 w/s change:
               IF NOT (tiletype(tiletodraw) = 10 OR tiletype(tiletodraw) = 8) THEN
                  IF DQBkey(17) THEN
                     DO UNTIL NOT DQBkey(17)
                     LOOP
                     IF NOT tileinf(tiletodraw, 1) = -1 THEN tileinf(tiletodraw, 1) = tileinf(tiletodraw, 1) + 100
                     IF tileinf(tiletodraw, 1) = -1 THEN tileinf(tiletodraw, 1) = 0
                  END IF
                  IF DQBkey(31) THEN
                     DO UNTIL NOT DQBkey(31)
                     LOOP
                     IF tileinf(tiletodraw, 1) = 0 THEN tileinf(tiletodraw, 1) = -1
                     IF tileinf(tiletodraw, 1) > 0 THEN tileinf(tiletodraw, 1) = tileinf(tiletodraw, 1) - 100
                  END IF
                  IF tileinf(tiletodraw, 1) < -1 THEN tileinf(tiletodraw, 1) = -1
                  IF tileinf(tiletodraw, 1) > 30000 THEN tileinf(tiletodraw, 1) = 30000
               ELSEIF tiletype(tiletodraw) = 8 THEN
                  'IF DQBkey(17) THEN
                  '   DO UNTIL NOT DQBkey(17)
                  '   LOOP
                  '   tileinf(tiletodraw, 1) = tileinf(tiletodraw, 1) + .1
                  'END IF
                  'IF DQBkey(31) THEN
                  '   DO UNTIL NOT DQBkey(31)
                  '   LOOP
                  '   tileinf(tiletodraw, 1) = tileinf(tiletodraw, 1) - .1
                  'END IF
                  'IF tileinf(tiletodraw, 1) < -2 THEN tileinf(tiletodraw, 1) = -2
                  'IF tileinf(tiletodraw, 1) > 2 THEN tileinf(tiletodraw, 1) = 2
               END IF

               'M key manually changes values:
               IF DQBkey(50) THEN
                  DO UNTIL NOT DQBkey(50)
                  LOOP
                  DQBclearLayer 0
                  ans$ = DQBinput$(0, "Enter tile info 1:", 0, 0, 2)
                  tileinf(tiletodraw, 1) = VAL(ans$)
                  ans$ = DQBinput$(0, "Enter tile info 2:", 0, 15, 2)
                  tileinf(tiletodraw, 2) = VAL(ans$)
                  ans$ = DQBinput$(0, "Enter tile info 3:", 0, 30, 2)
                  tileinf(tiletodraw, 3) = VAL(ans$)
                  ans$ = DQBinput$(0, "Enter tile info 4:", 0, 45, 2)
                  tileinf(tiletodraw, 4) = VAL(ans$)
                  ans$ = DQBinput$(0, "Enter tile info 5:", 0, 60, 2)
                  tileinf(tiletodraw, 5) = VAL(ans$)
               END IF

               'X key exits:
               IF DQBkey(45) THEN EXIT DO

               'Print the current tile info values:
               DQBprint 1, "Tile info 2:" + STR$(tileinf(tiletodraw, 2)), 0, 75, 2
               DQBprint 1, "Tile info 3:" + STR$(tileinf(tiletodraw, 3)), 0, 90, 2
               DQBprint 1, "Tile info 4:" + STR$(tileinf(tiletodraw, 4)), 0, 105, 2
               DQBprint 1, "Tile info 5:" + STR$(tileinf(tiletodraw, 5)), 0, 120, 2

               'Flip layers:
               DQBmouseHide
               DQBcopyLayer 1, 0
               DQBmouseShow

            LOOP

            'Save the info we changed:
            CLOSE
            OPEN "tiles.dat" FOR OUTPUT AS #1
            WRITE #1, numoftiles
            FOR i2 = 1 TO numoftiles
               WRITE #1, tiletype(i2), tileinf(i2, 1), tileinf(i2, 2), tileinf(i2, 3), tileinf(i2, 4), tileinf(i2, 5)
            NEXT i2
            CLOSE


         END IF


      'End tile info changing code
      
      'Select a tile:

      IF DQBmouseLB THEN
         'Determine which tile to select:
         'tempx = DQBmouseX / 16
         'tempy = DQBmouseY / 16

         IF DQBmouseX > 287 THEN GOTO skipselect:

         SelectTile = tiletodraw
         'tiletodraw = tempx + (tempy * 18)
        
        
         'tempx2 = emsx
         'tempy2 = emsy
        
        
         
         DO UNTIL NOT DQBmouseLB
         LOOP
         EXIT FUNCTION
      END IF
         
skipselect:

      IF DQBkey(KEYESC) THEN
         SelectTile = 1
         DO UNTIL NOT DQBkey(KEYESC)
         LOOP
         EXIT FUNCTION
      END IF

      IF DQBkey(KEYUP) THEN
         cpage = cpage - 1
         DO UNTIL NOT DQBkey(KEYUP)
         LOOP
      END IF
      IF DQBkey(KEYDOWN) THEN
         cpage = cpage + 1
         DO UNTIL NOT DQBkey(KEYDOWN)
         LOOP
      END IF
      IF cpage < 3 THEN cpage = 3
      IF cpage > 22 THEN cpage = 22





         tempx2 = INT(DQBmouseX / 16)
         tempy2 = INT(DQBmouseY / 16)
         tiletodraw = tempx2 + (tempy2 * 18) + ((cpage - 3) * 216)
emsy = INT(tiletodraw / 18)
emsx = ((tiletodraw / 18) - INT(tiletodraw / 18)) * 18
emspage = INT(emsy / 12)
emsy = emsy - (emspage * 12)
emspage = emspage + 3
IF NOT emspage = cpage THEN PLAY "mb l64 c"
tempx2 = emsx
tempy2 = emsy
      
      

      DQBmouseHide
      DQBcopyLayer cpage, 1
      DQBbox 1, tempx2 * 16, tempy2 * 16, (tempx2 * 16) + 16, (tempy2 * 16) + 16, 2
      DQBprint 1, STR$(tiletodraw), 275, 15, 15
      DQBcopyLayer 1, 0
      DQBmouseShow

   LOOP







END FUNCTION

