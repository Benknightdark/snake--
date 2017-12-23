#!/bin/bash

# filename: practice.sh
# snake game
# final exam 2017.12.18

#遊戲結束畫面
good_game=(
    '                                                 '
    '                G A M E  O V E R !               '
    '                                                 '
    '                   Score:                        '
    '          press   q   to quit                    '
    '          press   n   to start a new game        '
    '          press   s   to change the speed        '
    '                                                 '
);

#遊戲開始畫面
game_start=(
    '                                                 '
    '                ~~~ S N A K E ~~~                '
    '                                                 '
    '                  Author:  YIYUAN                   '
    '         space or enter   pause/play             '
    '         q                quit at any time       '
    '         s                change the speed       '
    '                                                 '
    '         Press <Enter> to start the game         '
    '                                                 '
);

#退出遊戲
snake_exit() 
{  
    stty echo;  #恢復回顯
    tput rmcup; #恢復屏幕
    tput cvvis; #恢復光標
    exit 0;
}

#畫面大小
draw_gui() 
{                                   
    clear;
    color="\e[34m*\e[0m";
    for (( i = 0; i < $1; i++ )); do
        echo -ne "\033[$i;0H${color}";
        echo -ne "\033[$i;$2H${color}";
    done

    for (( i = 0; i <= $2; i++ )); do
        echo -ne "\033[0;${i}H${color}";
        echo -ne "\033[$1;${i}H${color}";
    done

    ch_speed 0;
    echo -ne "\033[$Lines;$((yscore-10))H\e[36mScores: 0\e[0m";
    echo -en "\033[$Lines;$((Cols-50))H\e[33mPress <space> or enter to pause game\e[0m";
}

snake_init() 
{
    #取得螢幕的長寬
    Lines=`tput lines`; 
    Cols=`tput cols`;
    #設定開始的位置     
    xline=$((Lines/2)); 
    ycols=4;        
    #顯示分數的位置
    xscore=$Lines;
    yscore=$((Cols/2));
    #中心點位置
    xcent=$xline;
    ycent=$yscore;        
    #隨機點
    xrand=0;
    yrand=0;               
    #總分和點存在標記
    sumscore=0;
    liveflag=1;
    #總共要加長的節點和點的分數           
    sumnode=0;          
    foodscore=0; 
         
    #初始化貪吃蛇
    snake="0000 ";   
    #開始節點的方向                         
    pos=(right right right right right);
    #開始的各個節點的x座標
    xpt=($xline $xline $xline $xline $xline); 
    #開始的各個節點的y座標
    ypt=(5 4 3 2 1);     
    #速度 預設速度                    
    speed=(0.05 0.1 0.15);  spk=${spk:-1};  

    draw_gui $((Lines-1)) $Cols
}

#停止遊戲
game_pause() 
{                               
    echo -en "\033[$Lines;$((Cols-50))H\e[33mGame paused, Use space or enter key to continue\e[0m";
    while read -n 1 space; do
        [[ ${space:-enter} = enter ]] && \
            echo -en "\033[$Lines;$((Cols-50))H\e[33mPress <space> or enter to pause game           \e[0m" && return;
        [[ ${space:-enter} = q ]] && snake_exit;
    done
}

# $1 節點位置 
#更新各個節點座標
update() 
{                                   
    case ${pos[$1]} in
        right) ((ypt[$1]++));;
         left) ((ypt[$1]--));;
         down) ((xpt[$1]++));;
           up) ((xpt[$1]--));;
    esac
}

#更新速度
ch_speed() 
{                                  
     [[ $# -eq 0 ]] && spk=$(((spk+1)%3));
     case $spk in
         0) temp="Fast  ";;
         1) temp="Medium";;
         2) temp="Slow  ";;
     esac
     echo -ne "\033[$Lines;3H\e[33mSpeed: $temp\e[0m";
}

#更新方向
Go() 
{                                   
    case ${key:-enter} in
        j|J) [[ ${pos[0]} != "up"    ]] && pos[0]="down";;
        k|K) [[ ${pos[0]} != "down"  ]] && pos[0]="up";;
        h|H) [[ ${pos[0]} != "right" ]] && pos[0]="left";;
        l|L) [[ ${pos[0]} != "left"  ]] && pos[0]="right";;
        s|S) ch_speed;;
        q|Q) snake_exit;;
      enter) game_pause;;
    esac
}

#增加節點
add_node() 
{                                 
    snake="0$snake";
    pos=(${pos[0]} ${pos[@]});
    xpt=(${xpt[0]} ${xpt[@]});
    ypt=(${ypt[0]} ${ypt[@]});
    update 0;

    local x=${xpt[0]} y=${ypt[0]}
    (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; #撞牆

    for (( i = $((${#snake}-1)); i > 0; i-- )); do
        (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crashed
    done

    echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";
    return 0;
}

#產生隨機點和隨機數
mk_random() 
{                               
    xrand=$((RANDOM%(Lines-3)+2));
    yrand=$((RANDOM%(Cols-2)+2));
    foodscore=$((RANDOM%9+1));

    echo -ne "\033[$xrand;${yrand}H$foodscore";
    liveflag=0;
}

#重新開始新遊戲
new_game() 
{                                
    snake_init;
    while true; do
        read -t ${speed[$spk]} -n 1 key;
        [[ $? -eq 0 ]] && Go;

        ((liveflag==0)) || mk_random;
        if (( sumnode > 0 )); then
            ((sumnode--));
            add_node; (($?==0)) || return 1;
        else
            update 0; 
            echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";

            for (( i = $((${#snake}-1)); i > 0; i-- )); do
                update $i;
                echo -ne "\033[${xpt[$i]};${ypt[$i]}H\e[32m${snake[@]:$i:1}\e[0m";

                (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crashed
                [[ ${pos[$((i-1))]} = ${pos[$i]} ]] || pos[$i]=${pos[$((i-1))]};
            done
        fi

        local x=${xpt[0]} y=${ypt[0]}
        (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; #撞牆

        (( x==xrand && y==yrand )) && ((liveflag=1)) && ((sumnode+=foodscore)) && ((sumscore+=foodscore));

        echo -ne "\033[$xscore;$((yscore-2))H$sumscore";
    done
}

print_good_game() 
{
    local x=$((xcent-4)) y=$((ycent-25))
    for (( i = 0; i < 8; i++ )); do
        echo -ne "\033[$((x+i));${y}H\e[45m${good_game[$i]}\e[0m";
    done
    echo -ne "\033[$((x+3));$((ycent+1))H\e[45m${sumscore}\e[0m";
}

print_game_start() 
{
    snake_init;

    local x=$((xcent-5)) y=$((ycent-25))
    for (( i = 0; i < 10; i++ )); do
        echo -ne "\033[$((x+i));${y}H\e[45m${game_start[$i]}\e[0m";
    done

    while read -n 1 anykey; do
        [[ ${anykey:-enter} = enter ]] && break;
        [[ ${anykey:-enter} = q ]] && snake_exit;
        [[ ${anykey:-enter} = s ]] && ch_speed;
    done
    
    while true; do
        new_game;
        print_good_game;
        while read -n 1 anykey; do
            [[ $anykey = n ]] && break;
            [[ $anykey = q ]] && snake_exit;
        done
    done
}

game_main() 
{

if [ $(id -u) -eq 0 ]; then

    read -p '申請遊戲帳號請按1，登入遊戲請按2：' Option
    if [ $Option -eq 1 ]; then
    read -p "輸入申請遊戲帳號 : " username
	read -s -p "輸入申請遊戲密碼 : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username 此帳號已存在!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
    else
    return;
    fi
	
else
	echo "Only root may add a user to the system"
	exit 2
fi


    trap 'snake_exit;' SIGTERM SIGINT; 
    stty -echo;                               #取消回顯
    tput civis;                               #隱藏光標
    tput smcup; clear;                        #保存螢幕並清除紀錄

    print_game_start;                         #開始遊戲 
}

game_main;
