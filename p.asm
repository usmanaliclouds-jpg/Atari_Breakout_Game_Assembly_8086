org 100h

start:
    call load_high_score
    call clear_screen
    call display_welcome

wait_key:
    mov ah,0
    int 16h

    cmp al,0Dh
    jne check_esc
    jmp start_game

check_esc:
    cmp al,1Bh
    jne wait_key
    jmp exit_program

start_game:
    call init_game
    call clear_screen
    call draw_game_border
    call draw_bricks
    call draw_score
    call draw_paddle
    call draw_ball

game_loop:
    mov ah,01h
    int 16h
    jz no_key1
    
    mov ah,0
    int 16h
    
    cmp al,1Bh
    jne check_space_key
    jmp back_to_menu

check_space_key:
    cmp al,' '
    jne check_left_key
    jmp launch_ball
    
check_left_key:
    cmp ah,4Bh
    jne check_right_key
    jmp move_left
    
check_right_key:
    cmp ah,4Dh
    jne no_key1
    jmp move_right

no_key1:
    cmp byte [ball_active],1
    je update_ball1
    jmp game_loop

update_ball1:
    call delay_ball
    call clear_ball
    
    mov al,[ball_x]
    add al,[ball_dx]
    mov [ball_x],al
    
    mov al,[ball_y]
    add al,[ball_dy]
    mov [ball_y],al
    
    call check_wall_collision
    call check_paddle_collision
    call check_brick_collision
    call check_bottom
    
    call update_powerup
    
    call draw_ball
    
    cmp word [bricks_remaining],0
    jne game_loop
    jmp next_level

move_left:
    mov al,[paddle_x]
    sub al,2
    cmp al,2
    jl move_left_end
    
    cmp byte [ball_active],0
    jne move_left_skip_clear
    call clear_ball
    
move_left_skip_clear:
    sub byte [paddle_x],2
    
    cmp byte [ball_active],0
    jne move_left_done
    mov al,[paddle_x]
    add al,4
    mov [ball_x],al
    
move_left_done:
    call draw_paddle
    
    cmp byte [ball_active],0
    jne move_left_end
    call draw_ball

move_left_end:
    jmp game_loop

move_right:
    mov al,[paddle_x]
    add al,[paddle_width]
    add al,2
    cmp al,78
    jg move_right_end
    
    cmp byte [ball_active],0
    jne move_right_skip_clear
    call clear_ball
    
move_right_skip_clear:
    add byte [paddle_x],2
    
    cmp byte [ball_active],0
    jne move_right_done
    mov al,[paddle_x]
    add al,4
    mov [ball_x],al
    
move_right_done:
    call draw_paddle
    
    cmp byte [ball_active],0
    jne move_right_end
    call draw_ball

move_right_end:
    jmp game_loop

launch_ball:
    cmp byte [ball_active],0
    jne launch_ball_end
    mov byte [ball_active],1
    mov byte [ball_dx],1
    mov byte [ball_dy],-1

launch_ball_end:
    jmp game_loop

check_bottom:
    mov al,[ball_y]
    cmp al,23
    jge check_bottom_fall
    ret
    
check_bottom_fall:
    mov byte [ball_active],0
    dec byte [lives]
    call sound_lose_life
    cmp byte [lives],0
    jne check_bottom_reset
    jmp game_over
    
check_bottom_reset:
    cmp byte [powerup_active],1
    jne check_bottom_no_powerup_clear
    
    mov dh,[powerup_y]
    mov dl,[powerup_x]
    mov bh,0
    mov ah,02h
    int 10h
    mov ah,09h
    mov al,' '
    mov bl,0
    mov cx,1
    int 10h
    
check_bottom_no_powerup_clear:
    mov byte [paddle_width],8
    mov byte [powerup_active],0
    mov byte [powerup_delay_counter],0
    mov byte [double_points_active],0
    mov byte [double_points_timer],0
    
    call init_ball_position
    call draw_paddle
    call draw_ball
    call draw_score
    ret

next_level:
    inc byte [level]
    
    cmp byte [level],6
    jge win_game
    
    mov al,[ball_speed]
    cmp al,4
    jle next_level_skip_speed
    sub al,2
    mov [ball_speed],al
    
next_level_skip_speed:
    call clear_screen
    mov dh,10
    mov dl,0
    mov si,level_complete_msg
    call center_text
    call set_cursor
    mov al,[color_controls]
    mov [current_color],al
    call print_color_string
    
    mov dh,12
    mov dl,35
    call set_cursor
    mov si,next_level_msg
    call print_color_string
    mov al,[level]
    call print_number
    
    call sound_win
    
    mov ah,0
    int 16h
    
    call init_level
    call init_ball_position
    call clear_screen
    call draw_game_border
    call draw_bricks
    call draw_score
    call draw_paddle
    call draw_ball
    
    jmp game_loop

win_game:
    call sound_win
    call clear_screen
    mov dh,10
    mov dl,0
    mov si,congratulations_msg
    call center_text
    call set_cursor
    mov al,[color_controls]
    mov [current_color],al
    call print_color_string
    
    mov dh,12
    mov dl,30
    call set_cursor
    mov si,final_score_msg
    call print_color_string
    mov al,[score]
    call print_number
    
    mov dh,14
    mov dl,0
    mov si,win_msg
    call center_text
    call set_cursor
    call print_color_string
    
    mov ah,0
    int 16h
    jmp start

game_over:
    call sound_game_over
    call clear_screen
    
    mov dh,10
    mov dl,0
    mov si,game_over_msg
    call center_text
    call set_cursor
    mov al,[color_instr]
    mov [current_color],al
    call print_color_string
    
    mov dh,12
    mov dl,0
    mov si,your_score_msg
    call center_text
    call set_cursor
    call print_color_string
    mov al,[score]
    call print_number
    
    mov al,[score]
    cmp al,[high_score]
    jle game_over_no_new_high
    mov [high_score],al
    call save_high_score
    
    mov dh,14
    mov dl,0
    mov si,new_high_score_msg
    call center_text
    call set_cursor
    mov al,0x0E
    mov [current_color],al
    call print_color_string
    jmp game_over_show_instruction
    
game_over_no_new_high:
    
    mov dh,14
    mov dl,0
    mov si,high_score_label
    call center_text
    call set_cursor
    mov al,[color_desc]
    mov [current_color],al
    call print_color_string
    mov al,[high_score]
    call print_number
    
game_over_show_instruction:
    mov dh,16
    mov dl,0
    mov si,press_enter_msg
    call center_text
    call set_cursor
    mov al,[color_controls]
    mov [current_color],al
    call print_color_string
    
game_over_wait:
    mov ah,0
    int 16h
    cmp al,0Dh  
    jne game_over_wait
    jmp start

back_to_menu:
    jmp start

exit_program:
    call clear_screen
    mov dh, 12
    mov dl, 0
    mov si, exit_msg
    call center_text
    call set_cursor

    mov al, [color_instr]
    mov [current_color], al
    call print_color_string

    mov ax,4C00h
    int 21h

init_game:
    mov byte [paddle_x],36
    mov byte [paddle_y],22
    mov byte [paddle_width],8
    
    mov byte [score],0
    mov byte [lives],3
    mov byte [level],1
    mov byte [ball_speed],14
    
    mov byte [powerup_active],0
    mov byte [double_points_active],0
    mov byte [double_points_timer],0
    
    call init_level
    call init_ball_position
    ret

assign_scores_by_color:
    push ax
    push bx
    push cx
    push si
    push di
    
    mov si, brick_colors            
    mov di, brick_scores            
    mov cx, 40                      
    
assign_score_loop:
    mov al, [si]                    
    cmp al, 14                      
    je assign_score_4
    cmp al, 15                      
    je assign_score_4
    
    cmp al, 12                      
    je assign_score_3
    cmp al, 13                      
    je assign_score_3
    cmp al, 4                       
    je assign_score_3
    
    cmp al, 10                      
    je assign_score_2
    cmp al, 11                      
    je assign_score_2
    cmp al, 6                       
    je assign_score_2
    cmp al, 3                       
    je assign_score_2
    
    
    cmp al, 9                       
    je assign_score_1
    cmp al, 1                       
    je assign_score_1
    cmp al, 2                       
    je assign_score_1
    cmp al, 5                       
    je assign_score_1
    
    mov byte [di], 1
    jmp assign_score_next
    
assign_score_4:
    mov byte [di], 4
    jmp assign_score_next
    
assign_score_3:
    mov byte [di], 3
    jmp assign_score_next
    
assign_score_2:
    mov byte [di], 2
    jmp assign_score_next
    
assign_score_1:
    mov byte [di], 1
    
assign_score_next:
    inc si
    inc di
    loop assign_score_loop
    
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

init_level:
    mov word [bricks_remaining],40
    mov byte [powerup_active],0
    
    call init_brick_colors
    
    mov si,brick_data
    mov cx,40
init_level_active_loop:
    mov byte [si],1
    inc si
    loop init_level_active_loop
    
    call assign_scores_by_color
    
    ret
init_ball_position:
    mov al,[paddle_x]
    add al,4
    mov [ball_x],al
    mov byte [ball_y],21
    mov byte [ball_dx],0
    mov byte [ball_dy],0
    mov byte [ball_active],0
    ret

check_wall_collision:
    mov al,[ball_x]
    cmp al,2
    jle check_wall_hit_left
    cmp al,78
    jge check_wall_hit_right
    jmp check_wall_check_top
    
check_wall_hit_left:
    neg byte [ball_dx]
    mov byte [ball_x],2
    jmp check_wall_check_top
    
check_wall_hit_right:
    neg byte [ball_dx]
    mov byte [ball_x],78
    
check_wall_check_top:
    mov al,[ball_y]
    cmp al,1
    jg check_wall_done
    neg byte [ball_dy]
    mov byte [ball_y],1
check_wall_done:
    ret

check_paddle_collision:
    mov al,[ball_y]
    mov bl,[paddle_y]
    cmp al,bl
    jne check_paddle_no_collision
    
    mov al,[ball_dy]
    cmp al,0
    jle check_paddle_no_collision
    
    mov al,[ball_x]
    mov bl,[paddle_x]
    cmp al,bl
    jl check_paddle_no_collision
    
    mov bl,[paddle_x]
    add bl,[paddle_width]
    cmp al,bl
    jge check_paddle_no_collision
    
    neg byte [ball_dy]
    call sound_paddle_hit
    
    mov al,[ball_y]
    dec al
    mov [ball_y],al
    
    mov al,[ball_x]
    sub al,[paddle_x]
    mov bl,[paddle_width]
    shr bl,1
    
    cmp al,bl
    jl check_paddle_hit_left
    jg check_paddle_hit_right
    jmp check_paddle_no_collision
    
check_paddle_hit_left:
    mov byte [ball_dx],-1
    jmp check_paddle_no_collision
    
check_paddle_hit_right:
    mov byte [ball_dx],1
    
check_paddle_no_collision:
    ret

check_brick_collision:
    mov al,[ball_y]
    cmp al,2
    jge check_brick_y_ok1       
    jmp check_brick_no_hit
check_brick_y_ok1:
    cmp al,6
    jl check_brick_y_ok2        
    jmp check_brick_no_hit
check_brick_y_ok2:
    
    sub al,2
    xor ah,ah
    mov bl,10
    mul bl
    mov bx,ax
    
    mov al,[ball_x]
    sub al,5
    cmp al,0
    jge check_brick_x_ok        
    jmp check_brick_no_hit
check_brick_x_ok:
    
    xor ah,ah
    mov cl,7
    div cl
    
    cmp al,10
    jl check_brick_col_ok       
    jmp check_brick_no_hit
check_brick_col_ok:
    
    xor ah,ah
    add ax,bx
    
    cmp ax,40
    jl check_brick_idx_ok       
    jmp check_brick_no_hit
check_brick_idx_ok:
    
    mov si,brick_data
    add si,ax
    cmp byte [si],0
    jne check_brick_exists
    jmp check_brick_no_hit
check_brick_exists:
    
    mov byte [si],0
    dec word [bricks_remaining]
    
    push si
    push ax
    mov bx,si
    sub bx,brick_data
    mov si,brick_scores
    add si,bx
    mov al,[si]
    
    cmp byte [double_points_active],1
    jne no_double_points
    shl al,1
no_double_points:
    add [score],al
    
    cmp byte [double_points_active],1
    jne no_timer_dec
    dec byte [double_points_timer]
    cmp byte [double_points_timer],0
    jne no_timer_dec
    mov byte [double_points_active],0
no_timer_dec:
    
    pop ax
    mov bl,[ball_x]
    call spawn_powerup
    
    pop si
    
    neg byte [ball_dy]
    call sound_brick_break
    call draw_bricks
    call draw_score
    ret
    
check_brick_no_hit:
    ret

spawn_powerup:
    mov al,[ball_x]
    add al,[ball_y]
    and al,0x07
    cmp al,6
    jg spawn_powerup_do
    ret
    
spawn_powerup_do:
    cmp byte [powerup_active],1
    je spawn_powerup_end
    
    mov al,[ball_x]
    and al,0x03
    inc al
    mov [powerup_type],al
    
    cmp al,1
    jne check_powerup_type2
    mov byte [powerup_char],'W'
    jmp spawn_powerup_set
    
check_powerup_type2:
    cmp al,2
    jne check_powerup_type3
    mov byte [powerup_char],'X'
    jmp spawn_powerup_set
    
check_powerup_type3:
    cmp al,3
    jne check_powerup_type4
    mov byte [powerup_char],'L'
    jmp spawn_powerup_set
    
check_powerup_type4:
    mov byte [powerup_char],'S'
    
spawn_powerup_set:
    mov byte [powerup_active],1
    mov [powerup_x],bl
    mov byte [powerup_y],6
    
spawn_powerup_end:
    ret

update_powerup:
    cmp byte [powerup_active],0
    je update_powerup_end
    
    inc byte [powerup_delay_counter]
    cmp byte [powerup_delay_counter],8  
    jl update_powerup_skip_move
    mov byte [powerup_delay_counter],0
    
    mov dh,[powerup_y]
    mov dl,[powerup_x]
    mov bh,0
    mov ah,02h
    int 10h
    mov ah,09h
    mov al,' '
    mov bl,0
    mov cx,1
    int 10h
    
    inc byte [powerup_y]
    
update_powerup_skip_move:
    mov al,[powerup_y]
    cmp al,[paddle_y]
    jne update_powerup_check_bottom
    
    mov al,[powerup_x]
    mov bl,[paddle_x]
    cmp al,bl
    jl update_powerup_check_bottom
    
    mov bl,[paddle_x]
    add bl,[paddle_width]
    cmp al,bl
    jge update_powerup_check_bottom
    
    call apply_powerup
    mov byte [powerup_active],0
    ret
    
update_powerup_check_bottom:
    mov al,[powerup_y]
    cmp al,23
    jge update_powerup_deactivate
    
    mov dh,[powerup_y]
    mov dl,[powerup_x]
    mov bh,0
    mov ah,02h
    int 10h
    
    mov ah,09h
    mov al,[powerup_char]
    mov bl,0x0F
    mov cx,1
    int 10h
    ret
    
update_powerup_deactivate:
    mov byte [powerup_active],0
    
update_powerup_end:
    ret
    
apply_powerup:
    push ax
    push bx
    
    mov al,[powerup_type]
    
    cmp al,1
    jne check_apply_type2
    cmp byte [paddle_width],12
    jge apply_done
    mov al,[paddle_width]
    mov [original_paddle_width],al
    mov byte [paddle_width],12
    call sound_powerup
    jmp apply_done
    
check_apply_type2:
    cmp al,2
    jne check_apply_type3
    mov byte [double_points_active],1
    mov byte [double_points_timer],50
    call sound_powerup
    jmp apply_done
    
check_apply_type3:
    cmp al,3
    jne check_apply_type4
    inc byte [lives]
    call sound_powerup
    call draw_score
    jmp apply_done
    
check_apply_type4:
    mov al,[ball_speed]
    add al,4
    cmp al,20
    jle apply_slow_ok
    mov al,20
apply_slow_ok:
    mov [ball_speed],al
    call sound_powerup
    
apply_done:
    pop bx
    pop ax
    ret

draw_game_border:
    mov dh,0
    mov dl,0
    mov al,'+'
    mov bl,[color_border]
    call print_color_char

    mov dl,1
    mov cx,78
draw_border_top_loop:
    push cx
    mov al,'='
    mov bl,[color_border]
    call print_color_char
    inc dl
    pop cx
    loop draw_border_top_loop
    
    mov dl,79
    mov al,'+'
    mov bl,[color_border]
    call print_color_char
    
    mov dh,1
side_loop_border:
    cmp dh,23
    jb side_continue_border
    jmp side_done_border
side_continue_border:
    mov dl,0
    mov al,'|'
    mov bl,[color_border]
    call print_color_char
    mov dl,79
    mov al,'|'
    mov bl,[color_border]
    call print_color_char
    inc dh
    jmp side_loop_border
side_done_border:
    
    mov dh,23
    mov dl,0
    mov al,'+'
    mov bl,[color_border]
    call print_color_char
    
    mov dl,1
    mov cx,78
draw_border_bottom_loop:
    push cx
    mov al,'='
    mov bl,[color_border]
    call print_color_char
    inc dl
    pop cx
    loop draw_border_bottom_loop
    
    mov dl,79
    mov al,'+'
    mov bl,[color_border]
    call print_color_char
    
    ret

draw_bricks:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, brick_data              
    mov di, brick_colors            
    mov byte [line_counter], 4      
    mov dh, 2                           
    mov byte [current_row], 0
    
draw_bricks_row_loop:
    mov al, [current_row]
    cmp al, [line_counter]
    jb draw_bricks_row_continue
    jmp draw_bricks_done

draw_bricks_row_continue:
    mov dl, 5                       
    mov byte [current_col], 0
    
draw_bricks_col_loop:
    cmp byte [current_col], 10      
    jb draw_bricks_col_continue
    jmp draw_bricks_next_row

draw_bricks_col_continue:
    mov al, [si]
    cmp al, 0
    je draw_bricks_skip_brick
    
    mov bl, [di]
    
    mov bh, 0
    mov ah, 02h
    int 10h
    
    mov ah, 09h
    mov al, 0DBh                    
    push cx
    mov cx, 7                       
    int 10h
    pop cx
    jmp draw_bricks_next_brick
    
draw_bricks_skip_brick:
    mov bh, 0
    mov ah, 02h
    int 10h
    
    mov ah, 09h
    mov al, ' '
    mov bl, 0
    push cx
    mov cx, 7
    int 10h
    pop cx
    
draw_bricks_next_brick:
    inc si                          
    inc di                          
    add dl, 7                       
    inc byte [current_col]
    jmp draw_bricks_col_loop
    
draw_bricks_next_row:
    inc dh                          
    inc byte [current_row]
    jmp draw_bricks_row_loop
    
draw_bricks_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

init_brick_colors:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, 40h
    mov es, ax
    mov ax, [es:6Ch]                
    and al, 0x07                    
    add al, 9                       
    cmp al, 15
    jle init_colors_start_ok
    sub al, 7                       
    
init_colors_start_ok:
    mov [saved_color], al
    
    mov si, brick_colors            
    mov byte [current_row], 0
    
init_colors_row_loop:
    cmp byte [current_row], 4
    jb init_colors_row_continue
    jmp init_colors_done

init_colors_row_continue:
    mov al, [saved_color]
    mov bl, [current_row]
    add al, bl
    
    cmp al, 15
    jle init_colors_row_ok
    sub al, 7                       
    
init_colors_row_ok:
    cmp al, 7
    je init_fix_row_gray
    cmp al, 8
    je init_fix_row_gray
    cmp al, 0
    je init_fix_row_black
    jmp init_colors_row_final
    
init_fix_row_gray:
    mov al, 14                      
    jmp init_colors_row_final
    
init_fix_row_black:
    mov al, 12                      
    
init_colors_row_final:
    mov [temp_color], al
    mov byte [current_col], 0
    
init_colors_col_loop:
    cmp byte [current_col], 10
    jb init_colors_col_continue
    jmp init_colors_next_row

init_colors_col_continue:
    mov al, [temp_color]
    mov [si], al
    
    mov al, [current_col]
    and al, 0x01
    cmp al, 0
    je init_colors_no_adjust
    
    mov al, [temp_color]
    cmp al, 15
    jge init_wrap_color_down
    inc al                          
    jmp init_check_adjusted_color
    
init_wrap_color_down:
    mov al, 9                       
    
init_check_adjusted_color:
    cmp al, 7
    je init_colors_no_adjust        
    cmp al, 8
    je init_colors_no_adjust        
    cmp al, 0
    je init_colors_no_adjust        
    
    mov [temp_color], al
    
init_colors_no_adjust:
    inc si
    inc byte [current_col]
    jmp init_colors_col_loop
    
init_colors_next_row:
    inc byte [current_row]
    jmp init_colors_row_loop
    
init_colors_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_paddle:
    push ax
    push bx
    push cx
    push dx
    
    mov dh,[paddle_y]
    mov dl,2
    mov bh,0
    mov cx,76
draw_paddle_clear_loop:
    push cx
    push dx
    mov ah,02h
    int 10h
    mov ah,09h
    mov al,' '
    mov bl,0
    mov cx,1
    int 10h
    pop dx
    inc dl
    pop cx
    loop draw_paddle_clear_loop
    
    mov dh,[paddle_y]
    mov dl,[paddle_x]
    mov bh,0
    mov ah,02h
    int 10h
    
    mov ah,09h
    mov al,0DBh
    mov bl,0x09
    xor ch,ch
    mov cl,[paddle_width]
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_ball:
    push ax
    push bx
    push cx
    push dx
    
    mov dh,[ball_y]
    mov dl,[ball_x]
    mov bh,0
    mov ah,02h
    int 10h
    
    mov ah,09h
    mov al,248
    mov bl,0x0C
    mov cx,1
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear_ball:
    push ax
    push bx
    push cx
    push dx
    
    mov dh,[ball_y]
    mov dl,[ball_x]
    mov bh,0
    mov ah,02h
    int 10h
    
    mov ah,09h
    mov al,' '
    mov bl,0
    mov cx,1
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_score:
    mov dh,24
    mov dl,2
    call set_cursor
    
    mov si,score_label
    mov al,[color_desc]
    mov [current_color],al
    call print_color_string
    
    mov al,[score]
    call print_number
    
    mov dl,15
    call set_cursor
    mov si,lives_label
    call print_color_string
    
    mov al,[lives]
    call print_number
    
    mov dl,28
    call set_cursor
    mov si,level_label
    call print_color_string
    mov al,[level]
    call print_number
    
    mov dh,24
    mov dl,40
    mov bh,0
    mov ah,02h
    int 10h
    
    mov cx,30
draw_score_clear_hint:
    push cx
    mov ah,0Eh
    mov al,' '
    mov bh,0
    int 10h
    pop cx
    loop draw_score_clear_hint
    
    cmp byte [ball_active],0
    jne draw_score_check_2x
    
    mov dh,24
    mov dl,40
    call set_cursor
    mov si,launch_hint
    mov al,[color_instr]
    mov [current_color],al
    call print_color_string
    
draw_score_check_2x:
    cmp byte [double_points_active],0
    je draw_score_final
    
    mov dh,24
    mov dl,65
    call set_cursor
    mov si,double_points_msg
    mov al,0x0E
    mov [current_color],al
    call print_color_string
    
draw_score_final:
    ret

    
print_number:
    push ax
    push bx
    push dx
    push cx
    
    xor ah,ah
    
    mov bl,10
    div bl
    
    mov cl,ah
    
    push ax
    push cx
    mov ah,03h
    mov bh,0
    int 10h
    pop cx
    pop ax
    
    cmp al,0
    je skip_tens
    
    push ax
    push dx
    mov bh,0
    mov ah,02h
    int 10h
    pop dx
    pop ax
    
    add al,'0'
    mov ah,09h
    mov bh,0
    mov bl,[current_color]
    push cx
    mov cx,1
    int 10h
    pop cx
    
    inc dl
    
skip_tens:
    push ax
    mov bh,0
    mov ah,02h
    int 10h
    pop ax
    
    mov al,cl
    add al,'0'
    mov ah,09h
    mov bh,0
    mov bl,[current_color]
    push cx
    mov cx,1
    int 10h
    pop cx
    
    pop cx
    pop dx
    pop bx
    pop ax
    ret

clear_screen:
    mov ax,0003h
    int 10h
    call hide_cursor
    ret

hide_cursor:
    mov ah,01h
    mov ch,32
    mov cl,0
    int 10h
    ret

set_cursor:
    mov bh,0
    mov ah,02h
    int 10h
    ret

center_text:
    push si
    xor cx,cx
center_text_count:
    lodsb
    cmp al,0
    je center_text_done
    inc cx
    jmp center_text_count
center_text_done:
    mov ax,80
    sub ax,cx
    shr ax,1
    mov dl,al
    pop si
    ret

print_color_string:
    push dx
    mov ah,03h
    mov bh,0
    int 10h
print_color_string_next:
    lodsb
    cmp al,0
    je print_color_string_done
    
    push ax
    mov ah,02h
    mov bh,0
    int 10h
    pop ax
    
    mov ah,09h
    mov bh,0
    mov bl,[current_color]
    mov cx,1
    int 10h
    
    inc dl
    jmp print_color_string_next
print_color_string_done:
    pop dx
    ret

print_color_char:
    push ax
    push bx
    push cx
    
    mov bh,0
    mov ah,02h
    int 10h
    
    pop cx
    pop bx
    push bx
    push cx
    
    mov ah,09h
    mov bh,0
    mov cx,1
    int 10h
    
    pop cx
    pop bx
    pop ax
    ret

make_sound:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, ax
    mov al, 0B6h
    out 43h, al
    
    mov dx, 0012h
    mov ax, 34DCh
    div bx
    
    out 42h, al
    mov al, ah
    out 42h, al
    
    in al, 61h
    or al, 03h
    out 61h, al
    
sound_delay:
    push cx
    mov cx, 0xFFFF
sound_delay_inner:
    loop sound_delay_inner
    pop cx
    loop sound_delay
    
    in al, 61h
    and al, 0FCh
    out 61h, al
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

sound_paddle_hit:
    push ax
    push cx
    mov ax, 800
    mov cx, 2
    call make_sound
    pop cx
    pop ax
    ret

sound_brick_break:
    push ax
    push cx
    mov ax, 1200
    mov cx, 3
    call make_sound
    pop cx
    pop ax
    ret

sound_lose_life:
    push ax
    push cx
    mov ax, 600
    mov cx, 5
    call make_sound
    mov ax, 400
    mov cx, 5
    call make_sound
    mov ax, 200
    mov cx, 5
    call make_sound
    pop cx
    pop ax
    ret

sound_game_over:
    push ax
    push cx
    mov ax, 500
    mov cx, 8
    call make_sound
    mov ax, 350
    mov cx, 8
    call make_sound
    mov ax, 250
    mov cx, 12
    call make_sound
    pop cx
    pop ax
    ret

sound_win:
    push ax
    push cx
    mov ax, 523
    mov cx, 4
    call make_sound
    mov ax, 659
    mov cx, 4
    call make_sound
    mov ax, 784
    mov cx, 4
    call make_sound
    mov ax, 1047
    mov cx, 8
    call make_sound
    pop cx
    pop ax
    ret

sound_powerup:
    push ax
    push cx
    mov ax, 800
    mov cx, 2
    call make_sound
    mov ax, 1000
    mov cx, 2
    call make_sound
    mov ax, 1200
    mov cx, 3
    call make_sound
    pop cx
    pop ax
    ret

blink_text:
    push ax
    push bx
    push cx
    push dx
    push si

    mov [blink_row], dh
    mov [blink_col], dl
    mov [blink_str], si

blink_loop:
    mov ah,01h
    int 16h
    jnz blink_done

    mov dh,[blink_row]
    mov dl,[blink_col]
    call set_cursor
    mov si,[blink_str]
    mov al,[color_instr]
    mov [current_color],al
    call print_color_string

    mov cx,8
delay_on:
    call delay
    loop delay_on

    mov ah,01h
    int 16h
    jnz blink_done

    mov dh,[blink_row]
    mov dl,[blink_col]
    call set_cursor
    
    mov si,[blink_str]
erase_loop:
    lodsb
    cmp al,0
    je erase_done
    
    push dx
    mov ah,02h
    mov bh,0
    int 10h
    
    mov ah,09h
    mov al,' '
    mov bh,0
    mov bl,0
    mov cx,1
    int 10h
    
    pop dx
    inc dl
    jmp erase_loop
erase_done:

    mov cx,8
delay_off:
    call delay
    loop delay_off

    jmp blink_loop

blink_done:
    mov dh,[blink_row]
    mov dl,[blink_col]
    call set_cursor
    mov si,[blink_str]
    mov al,[color_instr]
    mov [current_color],al
    call print_color_string

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

delay:
    push cx
    mov cx,0FFFFh
delay_lp:
    loop delay_lp
    pop cx
    ret
delay_ball:
    push cx
    xor ch,ch
    mov cl,[ball_speed]
delay_ball_outer:
    push cx
    mov cx,0x4000
delay_ball_inner:
    loop delay_ball_inner
    pop cx
    loop delay_ball_outer
    pop cx
    ret

display_welcome:
    mov dh,10
    mov dl,0
    mov si,high_score_display
    call center_text
    call set_cursor
    mov al,[color_desc]
    mov [current_color],al
    call print_color_string
    mov al,[high_score]
    call print_number

    mov dh,0
    mov dl,0
    mov al,'|'
    mov bl,[color_border]
    call print_color_char

    mov dl,1
    call set_cursor
    mov si,screen_top_fill
    mov al,[color_border]
    mov [current_color],al
    call print_color_string

    mov dl,79
    mov al,'|'
    mov bl,[color_border]
    call print_color_char

    mov dh,1
side_loop_welcome:
    cmp dh,23
    jbe side_continue_welcome
    jmp side_done_welcome
side_continue_welcome:
    mov dl,0
    mov al,'|'
    mov bl,[color_border]
    call print_color_char
    mov dl,79
    mov al,'|'
    mov bl,[color_border]
    call print_color_char
    inc dh
    jmp side_loop_welcome
side_done_welcome:

    mov dh,24
    mov dl,0
    mov al,'|'
    mov bl,[color_border]
    call print_color_char

    mov dl,1
    call set_cursor
    mov si,screen_bottom_fill
    mov al,[color_border]
    mov [current_color],al
    call print_color_string

    mov dl,79
    mov al,'|'
    mov bl,[color_border]
    call print_color_char

    mov dh,2
    mov si,logo1
    call center_text
    call set_cursor
    mov al,[color_logo]
    mov [current_color],al
    call print_color_string

    mov dh,3
    mov si,logo2
    call center_text
    call set_cursor
    call print_color_string

    mov dh,4
    mov si,logo3
    call center_text
    call set_cursor
    call print_color_string

    mov dh,5
    mov si,logo4
    call center_text
    call set_cursor
    call print_color_string

    mov dh,6
    mov si,logo5
    call center_text
    call set_cursor
    call print_color_string

    mov dh,8
    mov si,description
    call center_text
    call set_cursor
    mov al,[color_desc]
    mov [current_color],al
    call print_color_string

    mov dh,12
    mov si,rules_title
    call center_text
    call set_cursor
    mov al,[color_rules]
    mov [current_color],al
    call print_color_string

    mov dh,13
    mov si,rule1
    call center_text
    call set_cursor
    call print_color_string

    mov dh,14
    mov si,rule2
    call center_text
    call set_cursor
    call print_color_string

    mov dh,15
    mov si,rule3
    call center_text
    call set_cursor
    call print_color_string

    mov dh,16
    mov si,rule4
    call center_text
    call set_cursor
    call print_color_string

    mov dh,18
    mov si,controls_title
    call center_text
    call set_cursor
    mov al,[color_controls]
    mov [current_color],al
    call print_color_string

    mov dh,19
    mov si,control1
    call center_text
    call set_cursor
    call print_color_string

    mov dh,20
    mov si,control2
    call center_text
    call set_cursor
    call print_color_string

    mov dh,23
    mov dl,25
    mov si,instructions
    call blink_text

    ret

load_high_score:
    push ax
    push bx
    push cx
    push dx
    
    mov ah,3Dh
    mov al,0            
    mov dx,high_score_file
    int 21h
    jc load_high_score_default  
    
    mov bx,ax           
    
    mov ah,3Fh
    mov cx,1
    mov dx,high_score
    int 21h
    
    mov ah,3Eh
    int 21h
    
    jmp load_high_score_done
    
load_high_score_default:
    mov byte [high_score],0
    
load_high_score_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

save_high_score:
    push ax
    push bx
    push cx
    push dx
    
    mov ah,3Ch
    mov cx,0            
    mov dx,high_score_file
    int 21h
    jc save_high_score_done
    
    mov bx,ax           
    
    mov ah,40h
    mov cx,1
    mov dx,high_score
    int 21h
    
    mov ah,3Eh
    int 21h
    
save_high_score_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

screen_top_fill    db "==============================================================================",0
screen_bottom_fill db "==============================================================================",0

logo1 db "    ____  ____  _____    _    _  __  ___  _   _ _____ ",0
logo2 db "   | __ )|  _ \| ___|  / \  | |/ / / _ \| | | |   _|",0
logo3 db "   |  _ \| |_) |  _|   / _ \ | ' / | | | | | | | | |  ",0
logo4 db "   | |) |  _ <| |__ / ___ \| . \ | || | || | | |  ",0
logo5 db "   |/|| \\//   \\|\\ \/ \/  ||  ",0

description     db "    Break all the bricks with your ball! ",0

rules_title     db ">> GAME RULES <<",0
rule1           db "  1. Use paddle to bounce the ball",0
rule2           db "  2. Break all bricks to win",0
rule3           db "  3. Do not let the ball fall!",0
rule4           db "  4. Each brick gives points",0

controls_title  db ">> CONTROLS <<",0
control1        db "  LEFT/RIGHT ARROWS - Move Paddle",0
control2        db "  SPACE - Launch Ball",0

instructions    db "      Press ENTER to Start",0
launch_hint     db "Press SPACE to launch!",0

exit_msg db "Thanks for playing BREAKOUT!",0
win_msg db "Press any key to return to menu...",0
lose_msg db "GAME OVER! Press any key...",0
score_label db "Score: ",0
lives_label db "Lives: ",0
level_label db "Level: ",0
level_complete_msg db "LEVEL COMPLETE!",0
next_level_msg db "Next Level: ",0
congratulations_msg db "CONGRATULATIONS!",0
final_score_msg db "Final Score: ",0
double_points_msg db "2X POINTS!",0

blink_row db 0
blink_col db 0
blink_str dw 0

current_color  db 0x0F

color_logo     db 0x0D
color_border   db 0x0E
color_desc     db 0x0F
color_rules    db 0x0A
color_controls db 0x0B
color_instr    db 0x0C

paddle_x db 36
paddle_y db 22
paddle_width db 8

ball_x db 40
ball_y db 21
ball_dx db 0
ball_dy db 0
ball_active db 0

score db 0
lives db 3
bricks_remaining dw 40
level db 1 
ball_speed db 5

temp_color db 0
saved_color db 0
line_counter db 5
current_row db 0
current_col db 0

brick_data times 40 db 1
brick_scores times 40 db 0
brick_colors times 40 db 0 

powerup_active db 0
powerup_x db 0
powerup_y db 0
powerup_type db 0
powerup_char db 'P'

double_points_active db 0
double_points_timer db 0
original_paddle_width db 8

powerup_delay_counter db 0      
high_score db 0                  
high_score_file db "BRKOUT.DAT",0  

game_over_msg db "GAME OVER!",0
your_score_msg db "Your Score: ",0
high_score_label db "High Score: ",0
new_high_score_msg db "*** NEW HIGH SCORE! ***",0
press_enter_msg db "Press ENTER to continue...",0

high_score_display db "High Score: ",0