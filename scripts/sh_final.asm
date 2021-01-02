;;=============================================================================;;   
;;                          Silent Hunter Game                                 ;;
;;                           Tested on DOSBox                                  ;;
;;=============================================================================;;
;;                  Created by: Abhishek|Saloni|Meryl|Samyak                   ;;
;;=============================================================================;;

Points MACRO  point, printablePoint
	mov al,point
	xor ah, ah 
	mov cl, 10 
	div cl 
	add ax, 3030h
	mov printablePoint,ax
	
ENDM Points  
Print MACRO row, column, color 
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, ' '
   mov Bl, color
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM Print     

PrintSubmarine MACRO row, column
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row ;24
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, 127  ;Arrow shape
   mov Bl, 0Eh
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintSubmarine    

PrintShot MACRO row, column
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, 254
   mov Bl, 0Ch
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintShot  

PrintText Macro row , column , text
   push ax
   push bx
   push cx
   push dx   
   
   mov ah,2
   mov bh,0
   mov dl,column
   mov dh,row
   int 10h
   mov ah, 9
   mov dx, offset text
   int 21h
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintText

Delete Macro row, column
   push ax
   push bx
   push cx
   push dx

   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   int 10h 
   mov Ah, 09
   mov Al, ' '
   mov Bl, 0h
   mov Cx, 1h
   int 10h 

   pop dx
   pop cx
   pop bx
   pop ax
ENDM Delete

Delay  Macro Seconds, MilliSeconds
    push ax
    push bx
    push cx
    push dx 
    push ds

    mov cx, Seconds		;Cx,Dx : number of microseconds to wait
    mov dx, MilliSeconds
    mov ah, 86h
    int 15h
	
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
ENDM Delay 


ClearScreen MACRO
        
    mov ax, 0600h  ;al=0 => Clear
    mov bh, 07     ;bh=07 => Normal Attributes              
    mov cx, 0      ;From (cl=column, ch=row)
    mov dl, 80     ;To dl=column
    mov dh, 25     ;To dh=row
    int 10h    
    
    ;Move cursor to the beginning of the screen 
    mov ax, 0
    mov ah, 2
    mov dx, 0
    int 10h   
    
ENDM ClearScreen
;=========================================
.MODEL SMALL
.STACK 64    
.DATA 
StartScreen			 db '              ====================================================',0ah,0dh
	db '             ||                                                  ||',0ah,0dh                                        
        db '             ||            >>      Silent Hunter      <<         ||',0ah,0dh
        db '             ||      Created by - Abhishek|Saloni|Meryl|Samyak   ||',0ah,0dh
	db '             ||__________________________________________________||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh          
	db '             ||           Use Arrow key to move the submarine    ||',0ah,0dh
	db '             ||          and space button to fire the torpedoes  ||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh
	db '             ||            You begin with 6 lifes, so score      ||',0ah,0dh
	db '             ||     the highest you can before you are detected  ||',0ah,0dh
	db '             ||        Scoring points will increase your lives.  ||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh
	db '             ||            Press Enter to start playing          ||',0ah,0dh 
	db '             ||            Press ESC to Exit                     ||',0ah,0dh
	db '              ====================================================',0ah,0dh
	db '$',0ah,0dh
GameoverScreen			 db '          __________________________________________________',0ah,0dh
	db '             ||                                                  ||',0ah,0dh                                        
	db '             ||               >> GAMEOVER <<                     ||',0ah,0dh
	db '             ||__________________________________________________||',0ah,0dh	
	db '$',0ah,0dh
ShipColLeft          db       ? 										 
ShipColRight         db       ? 
ShipColCenter	       db	?


ShipRow              db       15    
ShipColor            db      0d0h    

SubmarineRow             db      24
SubmarineCol             db      40
   
ShotRow                db      ?
ShotCol                db      ?
ShotStatus             db      0    						;1 means there exist a displayed shot, 0 otherwise

lifes                  db      6
Misses                 db      0
Hits                   db      0							;Score
PlayerName	       db      15, ?,  15 dup('$')
AskPlayerName	       db      'Enter your name: ','$'
Disp_Hits	       db      'Score: ??','$'
Disp_lifes             db      'lifes: ?','$'
GameTitle	       db      ' >>  Silent Hunter Game  >> ','$'
FinalScoreString       db      'Your final score is: ??','$'
ShipDirection	       db      0						;0=Left, 1=Right
EasyMode	       db      'Easy Mode','$'
HardMode	       db      'Hard Mode','$'
ExtremeMode	       db      'Extreme Mode','$'
Instruction	       db      'ESC: to exit; Space: to fire; Arrow Keys: to move','$'
separate			db		'>>','$'
;==================================================

.CODE   
MAIN    PROC FAR  
    mov ax, @DATA
    mov ds, ax  
    
  ClearScreen
  call StartMenu
  ClearScreen
  call DrawInterface
  call ResetShip
  PrintSubmarine 24 40
  call UpdateStrings
  
  MainLoop:
   cmp ShipDirection, 1
   jz moveShipRight
   call ShipMoveLeft
   jmp AfterShipMove
   
   moveShipRight:
   call ShipMoveRight
   
   AfterShipMove:
   cmp ShotStatus, 1
   jnz NoShotExist
   call CheckShotStatus			;Check see if the shotStatus alter to 0
   
   cmp ShotStatus, 1
   jnz NoShotExist
   call MoveShot
   PrintSubmarine SubmarineRow SubmarineCol		;since the shot deletes the shooter at the beginning
   
   NoShotExist:       
   mov ah,1h
   int 16h             			;ZF=1 when a key is pressed                        
   jz NokeyPress
   call KeyisPressed
   
   NokeyPress:
   call Difficulty
   
   EndOfMainLoop:
   jmp MainLoop
   hlt
MAIN        ENDP 

;==================================================
UpdateStrings Proc  
	 push ax
	 
     Points Hits, ax
	 mov Disp_Hits[8], ah
	 mov FinalScoreString[22], ah
	 mov Disp_Hits[7], al
	 mov FinalScoreString[21], al
		
     mov ah,lifes
     add ah, 30h
   	 mov Disp_lifes[7], ah
	
	PrintText 1 , 56 , Disp_Hits
	PrintText 1 , 70 , Disp_lifes	

	pop ax
	ret             
UpdateStrings ENDP 

;==================================================
ShipMoveLeft Proc   
    dec ShipColLeft
    Print   ShipRow ,ShipColLeft, ShipColor 
    Delete ShipRow, ShipColRight     
    dec ShipColRight  
    dec ShipColCenter
	
    cmp ShipColLeft ,0   
    Jnz endOfShipMoveLeft 
    call DeleteShip
    call ResetShip
    endOfShipMoveLeft: ret              
ShipMoveLeft ENDP 

;==================================================
ShipMoveRight Proc   
    inc ShipColRight
    Print   ShipRow ,ShipColRight, ShipColor 
    Delete ShipRow, ShipColLeft     
    inc ShipColLeft 
    inc ShipColCenter
	
    cmp ShipColRight ,80   
    Jnz endOfShipMoveRight 
    call DeleteShip
    call ResetShip
    endOfShipMoveRight: ret              
ShipMoveRight ENDP 

;==================================================
KeyisPressed  Proc 
    mov ah,0
    int 16h

    cmp ah,4bh                            ;Move Shooter Left if left button is pressed
    jnz NotLeftKey
    call MoveSubmarineLeft  
    jmp EndofKeyisPressed
	
    NotLeftKey:
    cmp ah,4dh					
    jnz NotRightKey			 ;Move Shooter Right if right button is pressed
    call MoveSubmarineRight
    jmp EndofKeyisPressed
	
    NotRightKey:
    cmp ah,48h					
    jnz NotUpKey			 ;Move Shooter Up if up button is pressed
    call MoveSubmarineUp
    jmp EndofKeyisPressed

    NotUpKey:
    cmp ah,50h					
    jnz NotDownKey			 ;Move Shooter Down if down button is pressed
    call MoveSubmarineDown
    jmp EndofKeyisPressed

    NotDownKey:
    cmp ah,1H                 	 ;Esc to exit the game

	Jnz NotESCKey
	call Gameover 
		
	NotESCKey:
    cmp ah,39h                            ;go spaceKey if up button is pressed

    jnz EndofKeyisPressed
    cmp ShotStatus, 1
    jz EndofKeyisPressed
    mov al,1                      	  ;intialize a new shot
    mov ShotStatus,1 
    mov al, SubmarineCol
    mov ShotCol, al
    mov al, SubmarineRow ;24				  ;it will be decremented in the new MainLoop
    mov ShotRow,al 
			
    EndofKeyisPressed:
    ret
KeyisPressed  ENDP 

;==================================================
MoveSubmarineLeft   Proc  
     cmp SubmarineCol, 0
     JZ NoMoveLeft
     dec SubmarineCol
     PrintSubmarine SubmarineRow SubmarineCol 
     mov al, SubmarineCol   
     inc al
     Delete SubmarineRow, al
    NoMoveLeft:
    ret
MoveSubmarineLeft   ENDP 

;==================================================
MoveSubmarineRight  Proc 
     cmp SubmarineCol, 79
     JZ NoMoveRight
     inc SubmarineCol
     PrintSubmarine SubmarineRow SubmarineCol  
     mov al, SubmarineCol   
     dec al
     Delete SubmarineRow, al 
     NoMoveRight:
     ret
MoveSubmarineRight  ENDP 

;==================================================
MoveSubmarineUp  Proc  
     cmp SubmarineRow, 5
     JZ NoMoveUp
     dec SubmarineRow
     PrintSubmarine SubmarineRow SubmarineCol 
     mov al, SubmarineRow   
     inc al
     Delete al, SubmarineCol ;al
    NoMoveUp:
    ret
MoveSubmarineUp  ENDP 

;==================================================
MoveSubmarineDown  Proc  
     cmp SubmarineRow, 24
     JZ NoMoveDown
     inc SubmarineRow
     PrintSubmarine SubmarineRow SubmarineCol 
     mov al, SubmarineRow   
     dec al
     Delete al, SubmarineCol ; al
    NoMoveDown:
    ret
MoveSubmarineDown  ENDP 

;==================================================
MoveShot  Proc 
    dec ShotRow
    PrintShot ShotRow,ShotCol 
    mov al, ShotRow  
    inc al
    delete al, ShotCol    
    ret
MoveShot  ENDP 

;==================================================
CheckShotStatus  Proc
    push ax
	
    mov ah,ShipRow
    inc ah              			;Checking the row to be drawn if occupied by a rocket
    cmp ah, ShotRow  
    JNZ CheckEndRange 
						;Check if it was a successful hit
        mov al,ShotCol
        cmp al, ShipColLeft
        JZ Hit      
		cmp al, ShipColCenter
		JZ Hit
        cmp al, ShipColRight
        JZ Hit 	
		cmp ShipDirection, 0
		jnz RightDirection
		mov ah, ShipColLeft
		dec ah
		cmp al, ah
        JZ Hit
		jmp CheckEndRange
		RightDirection:
		mov ah, ShipColRight
		inc ah
		cmp al, ah
        JZ Hit
		
   ;==================================================
   CheckEndRange:
	 cmp ShotRow, 2			
	 jnz noChange			
	 dec Lifes
	 cmp lifes, 0
     jnz ResetTheShot
     call Gameover
	 
     Hit: inc Hits
	 inc lifes
	 call DeleteShip
	 call ResetShip
	 ResetTheShot:
     call ResetShot
     call UpdateStrings
     noChange:
	 
    pop ax
    ret    
CheckShotStatus ENDP 

;==================================================
Difficulty Proc
	
	cmp Hits, 5
	jle EasyGame					
	cmp Hits, 10
	jle HardGame
	Delay 0,20000
	PrintText 0, 67, ExtremeMode    ;Extreme Mode when 10<Hits
	jmp EndDifficulty
	
        HardGame: Delay 1,20000         ;Hard Mode when 10<=Hits<5
	PrintText 0, 70, HardMode
	jmp EndDifficulty
	
        EasyGame: Delay 2,0              ;Easy Mode when Hits<=5
	EndDifficulty:
	ret
Difficulty ENDP
;==================================================
DeleteShip Proc
	 Delete ShipRow, ShipColLeft
	 Delete ShipRow, ShipColCenter
	 Delete ShipRow, ShipColRight
	ret
DeleteShip ENDP

;==================================================
RandomiseShipRow Proc    
   push ax
   push bx
   push cx
   push dx 
   
   ; Range of row= [5,24]
   mov ah, 2ch                
   int 21h                      		; get system time where DH = second   Dl=MilliSeconds
   xor ax, ax
   mov al, dl
   mov bl, 20					; That limits the remainder to be [0,19]
   div bl
   add ah, 3					;The range would be= [3,22]
   mov ShipRow, ah   	 		
   
   ;Change the color of rocket
   NotBlack:
   add ShipColor ,10h				;Add one to background color
   mov ah, ShipColor
   and ah, 10h
   cmp ah ,00h
   jz NotBlack
        
   pop dx
   pop cx
   pop bx
   pop ax
   ret  
RandomiseShipRow ENDP 

;==================================================
ResetShip Proc
    call RandomiseShipDirection
	call RandomiseShipRow
	
	cmp ShipDirection, 1
	jnz movementLeft
	mov ShipColLeft, 0	 
    mov ShipColCenter, 1
	mov ShipColRight, 2
	jmp EndOfResetShip
	
	movementLeft:
	mov ShipColLeft, 78	
	mov ShipColCenter, 79
	mov ShipColRight, 80
    
    EndOfResetShip: 
    ret 
ResetShip ENDP 

;==================================================
RandomiseShipDirection Proc
   push ax
   push bx
   push cx
   push dx 

   mov ah, 2ch                
   int 21h                      ; get system time where DH = second   Dl=MilliSeconds
   xor ax, ax
   mov al, dl
   mov bl, 2					;That limits the remainder to be [0,1]
   div bl						
   mov ShipDirection,ah

   pop dx
   pop cx
   pop bx
   pop ax
   ret  
	ret
RandomiseShipDirection ENDP

;==================================================
ResetShot Proc
	 Delete ShotRow, ShotCol  
     mov al,0          
     mov ShotStatus,al 
	ret
ResetShot ENDP 
;==================================================
StartMenu Proc
    
	push ax
	push bx
	push cx
	push dx
	push ds 

	ClearScreen
	LoopOnName:
	PrintText 8,8,AskPlayerName

	;Receive player name from the user
	mov ah, 0Ah
	mov dx, offset PlayerName
	int 21h

	cmp PlayerName[1], 0	;Check that input is not empty
	jz LoopOnName

	;Checks on the first letter to ensure that it's either a capital letter or a small letter
	cmp PlayerName[2], 40h
	jbe LoopOnName
	cmp PlayerName[2], 7Bh
	jae LoopOnName
	cmp PlayerName[2], 60h
	jbe	anotherCheck
	ja ExitLoopOnName
	anotherCheck:
	cmp PlayerName[2], 5Ah
	ja	LoopOnName

	ExitLoopOnName:
	ClearScreen
	PrintText 1,1,StartScreen	

	;hide cursor
	 mov ah,01h
	                ;If bit 5 of CH is set, that often means "Hide cursor". So CX=2607h is an invisible cursor.
	 mov cx,2607h 
	 int 10h

	checkforinput:
	mov AH,0            		 
	int 16H 

	cmp al,13              		     ;Enter to Start Game   
	JE StartTheGame

	cmp ah,1H                 		 ;Esc to exit the game
	JE ExitMenu
	JNE checkforinput

	ExitMenu:
	mov ah,4CH
	int 21H

	StartTheGame: 
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax 
	RET
StartMenu ENDP
;==================================================
 Gameover Proc 
 ClearScreen

 PrintText 1, 30, PlayerName
 PrintText 3, 25,FinalScoreString
 PrintText 5, 5 ,GameoverScreen

 
    mov ah,4CH
    int 21H 
    ret
 Gameover ENDP 
;==================================================
DrawInterface	Proc
	
	push ax
	push cx
	push dx
	
	;Go to the line beginning
	
	mov al, 0
	mov cx, 80
	DrawLineloop1:
		Print 1, al, 30h
		inc al
	loop DrawLineloop1
	
	mov al,0
	mov cx, 65
	DrawLineloop2:
		Print 0, al, 70h
		inc al
	loop DrawLineloop2
	
	mov al,' '
	mov PlayerName[0],al
	mov PlayerName[1],al
	PrintText 1 , 0 , PlayerName
	PrintText 1 , 56 , Disp_Hits
	PrintText 1 , 70 , Disp_lifes	
	PrintText 1 , 24 , GameTitle
	PrintText 0, 70, EasyMode
	PrintText 0, 2, Instruction
	PrintText 1, 67,separate
	pop dx
	pop cx
	pop ax
	RET
DrawInterface	ENDP

;==================================================
END MAIN    
